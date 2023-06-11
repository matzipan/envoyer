use log::{debug, error, info};

use gtk::glib;

use melib::{backends::BackendMailbox, BackendEventConsumer};

use std::boxed::Box;
use std::collections::HashMap;
use std::rc::Rc;
use std::sync::Arc;
use std::time::Instant;

use crate::backends::imap;
use crate::controllers::ApplicationMessage;
use crate::google_oauth;
use crate::models;
use crate::services;

pub enum SyncType {
    Fresh,
    Update,
}

#[derive(Clone, Debug)]
pub struct Identity {
    pub bare_identity: Rc<models::BareIdentity>,
    backend: Rc<Box<imap::ImapBackend>>,
    store: Rc<services::Store>,
    application_message_sender: glib::Sender<ApplicationMessage>,
}

impl Identity {
    pub async fn new(
        bare_identity: models::BareIdentity,
        store: Rc<services::Store>,
        application_message_sender: glib::Sender<ApplicationMessage>,
    ) -> Identity {
        info!("Creating identity with address {}", bare_identity.email_address);

        //@TODO do the thread token response fetch asynchronously so that the
        //@TODO application does not have to wait for this to start up
        let access_token_response = google_oauth::refresh_access_token(&bare_identity.gmail_refresh_token)
            .await
            .unwrap();

        let imap_backend = imap::ImapBackend::new(
            "imap.gmail.com".to_string(),
            993,
            bare_identity.email_address.clone(),
            format!(
                "user={}\x01auth=Bearer {}\x01\x01",
                &bare_identity.email_address, &access_token_response.access_token
            ),
            true,
            true,
            false,
            true,
            BackendEventConsumer::new(Arc::new(|_, _| {})),
        )
        .unwrap();

        info!("Identity for {} created", bare_identity.email_address);
        return Identity {
            bare_identity: Rc::new(bare_identity),
            backend: Rc::new(imap_backend),
            store,
            application_message_sender,
        };
    }

    pub async fn initialize(self: Rc<Self>) -> Result<(), String> {
        info!("Initializing identity with address {}", self.bare_identity.email_address);

        //@TODO how does LSUB come into play/ only filter for subscribed?
        self.clone().sync_folders().await?;

        for folder in self.store.get_folders(&self.bare_identity)? {
            self.clone().sync_messages_for_folder(&folder, SyncType::Fresh).await?;
        }

        info!("Finished identity initialization for {}", self.bare_identity.email_address);
        Ok(())
    }

    pub async fn start_session(self: Rc<Self>) {
        info!("Syncing folders");
        self.clone().sync_folders().await.map_err(|e| {
            //@TODO show in UI
            error!("{}", e);
        });

        // @TODO if sync_folders failed twice (init and start_session), then there can
        // be no INBOX folder
        let inbox_folder = self
            .store
            .get_folders(&self.bare_identity)
            .unwrap()
            .iter()
            .find(|&x| x.folder_name == "INBOX")
            .unwrap()
            .clone();

        info!("Syncing messages");

        let sync_result = self.clone().sync_messages_for_folder(&inbox_folder, SyncType::Update).await;

        self.clone().handle_sync_messages_for_folder_result(&inbox_folder, sync_result);

        self.clone().sync_messages_for_non_inbox_folders().await.map_err(|e| {
            //@TODO show in UI
            error!("{}", e);
        });

        info!("Watching for changes");
        loop {
            let watch_return_reason = self
                .backend
                .watch_folder(&inbox_folder, std::time::Duration::from_secs(5 * 60))
                .await;

            match watch_return_reason {
                Ok(imap::WatchReturnReason::Updates(_)) => {
                    info!("Watching found updates on INBOX");

                    let sync_result = self.clone().sync_messages_for_folder(&inbox_folder, SyncType::Update).await;

                    self.clone().handle_sync_messages_for_folder_result(&inbox_folder, sync_result);
                }
                Ok(imap::WatchReturnReason::Timeout) => {
                    info!("Watching timed out with no updates");

                    info!("Syncing folders");
                    self.clone().sync_folders().await.map_err(|e| {
                        //@TODO show in UI
                        error!("{}", e);
                    });

                    self.clone().sync_messages_for_non_inbox_folders().await.map_err(|e| {
                        //@TODO show in UI
                        error!("{}", e);
                    });
                }
                Err(e) => {
                    //@TODO show in UI
                    error!("{}", e);
                }
            }
        }
    }

    async fn sync_messages_for_non_inbox_folders(self: Rc<Self>) -> Result<(), String> {
        let folders = self.store.get_folders(&self.bare_identity)?;

        for folder in folders.iter().filter(|x| x.folder_name != "INBOX") {
            // @TODO if the folders changed in the meanwhile and the last sync somehow
            // failed, we need to check if the folder actually exists
            let sync_result = self.clone().sync_messages_for_folder(&folder, SyncType::Update).await;

            self.clone().handle_sync_messages_for_folder_result(&folder, sync_result);
        }

        Ok(())
    }

    fn handle_sync_messages_for_folder_result(
        self: Rc<Self>,
        sync_folder: &models::Folder,
        sync_result: Result<Option<Vec<models::NewMessage>>, String>,
    ) {
        match sync_result {
            Err(e) => {
                //@TODO show in UI
                error!("{}", e);
            }
            Ok(Some(new_messages)) => {
                self.application_message_sender
                    .send(ApplicationMessage::NewMessages {
                        new_messages,
                        folder: sync_folder.clone(),
                        identity: self.clone(),
                    })
                    .expect("Unable to send application message");
            }
            Ok(None) => {}
        }
    }

    async fn fetch_folders(self: Rc<Self>) -> Result<Vec<Box<melib::backends::imap::ImapMailbox>>, String> {
        self.backend
            .is_online()
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())?;

        let mailboxes = self
            .backend
            .mailboxes()
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())?;

        // for mailbox in mailboxes.values_mut() {
        //     //@TODO
        //     let mailbox_usage = if mailbox.special_usage() !=
        // SpecialUsageMailbox::Normal {         Some(mailbox.
        // special_usage())     } else {
        //         let tmp =
        // SpecialUsageMailbox::detect_usage(mailbox.name());
        //         if tmp != Some(SpecialUsageMailbox::Normal) && tmp !=
        // None {             let _ =
        // mailbox.set_special_usage(tmp.unwrap());
        //         }
        //         tmp
        //     };
        // }

        let folders = mailboxes
            .values()
            .filter(|x| !x.no_select)
            .cloned()
            .collect::<Vec<Box<melib::backends::imap::ImapMailbox>>>();

        Ok(folders)
    }

    async fn sync_folders(self: Rc<Self>) -> Result<(), String> {
        let mailboxes = self.clone().fetch_folders().await?; //@TODO rename to fetch mailboxes

        // This is used to detect local folders removed from the server
        let mut leftover_folders_store: HashMap<_, _> = self
            .store
            .get_folders(self.bare_identity.as_ref())?
            .into_iter()
            .map(|folder| (folder.folder_path.clone(), folder))
            .collect();

        for mailbox_value in mailboxes.iter() {
            let mailbox_path = mailbox_value.path().to_string();

            match leftover_folders_store.get(&mailbox_path) {
                Some(_) => {
                    debug!(
                        "Found folder {} locally for identity {}. Removing from leftover set",
                        &mailbox_path,
                        self.bare_identity.as_ref().email_address
                    );
                    leftover_folders_store.remove(&mailbox_path);
                }
                None => {
                    debug!(
                        "Did not find folder {} locally for identity {}. Inserting in database",
                        &mailbox_path,
                        self.bare_identity.as_ref().email_address
                    );
                    self.store.store_folder_for_mailbox(self.bare_identity.as_ref(), &mailbox_value)?;
                }
            }
        }

        for (folder_path, folder_value) in leftover_folders_store.iter() {
            debug!(
                "Detected that folder {} for identity {} is not on the server. Removing from database",
                &folder_path,
                self.bare_identity.as_ref().email_address
            );
            self.store.remove_folder(self.bare_identity.as_ref(), &folder_value)?;
        }

        //@TODO trigger application event to reload folders

        Ok(())
    }

    // fn fetch_messages_for_folder(
    //     &self,
    //     folder: &models::Folder,
    // ) -> Result<Pin<Box<dyn Stream<Item = Result<melib::email::Mail,
    // melib::error::MeliError>>>>, String> {     // if let Ok(mut mailbox_job)
    // = backend.fetch(inbox.hash()) {

    //     let mut mailbox_job = self
    //         .backend
    //         .read()
    //         .unwrap()
    //         .sync(folder.folder_path.clone(), imap::SyncType::Fresh)
    //         .unwrap();

    //     let backend_clone = self.backend.clone();

    //     Err("".to_string())

    //     // Ok(Box::pin(async_stream::stream! {
    //     //     let backend_clone = backend_clone.clone();

    //     //     // while let Some(envelope_chunk) = mailbox_job.next().await {
    //     //     //     let envelope_chunk = envelope_chunk.unwrap();

    //     //     //     for envelope in envelope_chunk {
    //     //     //         let operation =
    // backend_clone.read().unwrap().operation(envelope.hash()).unwrap();     //
    // //         // yield
    // String::from_utf8(operation.as_bytes().unwrap().await.unwrap());     //
    // //         yield
    // melib::email::Mail::new(operation.as_bytes().unwrap().await.unwrap(), None);
    //     //     //     }
    //     //     // }

    //     //     return;
    //     // }))
    // }

    async fn sync_messages_for_folder(
        self: Rc<Self>,
        folder: &models::Folder,
        sync_type: SyncType,
    ) -> Result<Option<Vec<models::NewMessage>>, String> {
        let backend_sync_type = match sync_type {
            SyncType::Fresh => imap::SyncType::Fresh,
            SyncType::Update => {
                if let Some((max_uid, uid_validity)) = self.store.get_max_uid_and_uid_validity_for_folder(folder)? {
                    imap::SyncType::Update { max_uid, uid_validity }
                } else {
                    imap::SyncType::Fresh
                }
            }
        };

        debug!("Syncing messages for folder {}, checking if online", folder.folder_name);
        self.backend
            .is_online()
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())?;

        debug!("Online, syncing");
        // @TODO asyncstream while let Some(bla) = x.next().await { }

        let (new_uid_validity, mut new_messages, flag_updates) = self
            .backend
            .sync(folder.folder_path.clone(), backend_sync_type.clone())
            .await
            .map_err(|e| e.to_string())?;

        let now = Instant::now();

        debug!("Saving fetched data to store");
        let new_messages = match backend_sync_type {
            imap::SyncType::Fresh => {
                self.store
                    .store_messages_for_folder(&mut new_messages, folder, services::StoreType::Fresh { new_uid_validity })?;

                None
            }
            imap::SyncType::Update {
                max_uid: _,
                uid_validity: current_uid_validity,
            } => {
                if new_uid_validity == current_uid_validity {
                    debug!("UID validity match");

                    match flag_updates {
                        Some(flag_updates) => {
                            self.store.store_message_flag_updates_for_folder(&flag_updates)?;

                            // We use this to filter out expunged messages, but we need to run this before
                            // storing new messages. Otherwise we'll just delete the newly added messages
                            self.store
                                .keep_only_uids_for_folder(&flag_updates.iter().map(|x| x.uid).collect::<_>(), folder)?;
                        }
                        None => {}
                    };

                    // This needs to happen before the call to "Keep only uids for folder"
                    self.store
                        .store_messages_for_folder(&mut new_messages, folder, services::StoreType::Incremental)?;

                    Some(new_messages)
                } else {
                    debug!("UID validity mismatch");

                    self.store
                        .store_messages_for_folder(&mut new_messages, folder, services::StoreType::Fresh { new_uid_validity })?;

                    None
                }
            }
        };

        debug!("Finished saving data. Took {} seconds.", now.elapsed().as_millis() as f32 / 1000.0);

        Ok(new_messages)
    }

    pub fn is_message_content_downloaded(&self, conversation_id: i32) -> Result<bool, String> {
        self.store.is_message_content_downloaded(conversation_id)
    }

    pub async fn fetch_message_content(self: Rc<Self>, conversation_id: i32) -> Result<(), String> {
        //@TODO handle case when this returns error
        let message = self.store.get_message(conversation_id).expect("Unable to get message");
        let folder = self.store.get_folder(message.folder_id).expect("Unable to get folder");

        debug!(
            "Fetching content for message uid {} in folder {}, checking if online",
            message.uid, &folder.folder_path
        );

        self.backend
            .is_online()
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())?;

        debug!("Online, fetching");

        let message_content = self
            .backend
            .fetch_message_content(&folder.folder_path, message.uid)
            .map_err(|e| e.to_string())?
            .await
            .map_err(|e| e.to_string())?;

        self.store.store_content_for_message(message_content, &message)?;

        Ok(())
    }

    pub fn get_folders(&self) -> Result<Vec<models::Folder>, String> {
        self.store.get_folders(&self.bare_identity)
    }

    pub fn get_conversations_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::Message>, String> {
        self.store.get_messages_for_folder(folder)
    }
}
