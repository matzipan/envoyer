use futures::prelude::*;

use log::{debug, error, info};

use gtk::glib;

use melib::{backends::BackendMailbox, BackendEventConsumer};

use std::boxed::Box;
use std::collections::HashMap;
use std::pin::Pin;
use std::time::Instant;

use std::sync::{Arc, RwLock};

use async_stream;

use crate::google_oauth;
use crate::imap;
use crate::models;
use crate::services;

pub type ResultFuture<T> = Result<Pin<Box<dyn Future<Output = Result<T, String>> + Send + 'static>>, String>;

pub enum SyncType {
    Fresh,
    Update,
}

#[derive(Clone)]
pub struct Identity {
    bare_identity: Arc<models::BareIdentity>,
    backend: Arc<RwLock<Box<imap::ImapBackend>>>,
    store: Arc<services::Store>,
}

impl Identity {
    pub async fn new(bare_identity: models::BareIdentity, store: Arc<services::Store>) -> Identity {
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
            bare_identity: Arc::new(bare_identity),
            backend: Arc::new(RwLock::new(imap_backend)),
            store,
        };
    }

    pub async fn initialize(&self) -> Result<(), String> {
        info!("Initializing identity with address {}", self.bare_identity.email_address);

        //@TODO how does LSUB come into play/ only filter for subscribed?
        self.sync_folders()?.await?;

        for folder in self.store.get_folders(&self.bare_identity)? {
            if folder.folder_name != "INBOX" {
                continue;
            }

            self.sync_messages_for_folder(&folder, SyncType::Fresh)?.await?;
        }

        info!("Finished identity initialization for {}", self.bare_identity.email_address);
        Ok(())
    }

    pub fn start_session(&self) {
        // @TODO self.start_listening_for_updates();

        let sync_folder_job = self.sync_folders().expect("BLA");
        let sync_messages_for_index_job = self
            .sync_messages_for_folder(
                self.store
                    .get_folders(&self.bare_identity)
                    .unwrap()
                    .iter()
                    .find(|&x| x.folder_name == "INBOX")
                    .unwrap(),
                SyncType::Update,
            )
            .expect("BLA");
        // @TODO sync other folders than inbox

        let context = glib::MainContext::default();
        context.spawn(async move {
            sync_folder_job.await.map_err(|e| {
                //@TODO show in UI
                error!("{}", e);
            });
            sync_messages_for_index_job.await.map_err(|e| {
                //@TODO show in UI
                error!("{}", e);
            });
        });
    }

    fn fetch_folders(&self) -> ResultFuture<Vec<Box<melib::backends::imap::ImapMailbox>>> {
        let mailboxes_job = self
            .backend
            .read()
            .map_err(|e| e.to_string())?
            .mailboxes()
            .map_err(|e| e.to_string())?;

        let online_job = self
            .backend
            .read()
            .map_err(|e| e.to_string())?
            .is_online()
            .map_err(|e| e.to_string())?;

        Ok(Box::pin(async move {
            online_job.await.map_err(|e| e.to_string())?;
            mailboxes_job.await.map_err(|e| e.to_string()).map(|mailboxes| {
                // for mailbox in mailboxes.values_mut() {
                //     //@TODO
                //     let mailbox_usage = if mailbox.special_usage() !=
                // SpecialUsageMailbox::Normal {         Some(mailbox.
                // special_usage())     } else {
                //         let tmp = SpecialUsageMailbox::detect_usage(mailbox.name());
                //         if tmp != Some(SpecialUsageMailbox::Normal) && tmp != None {
                //             let _ = mailbox.set_special_usage(tmp.unwrap());
                //         }
                //         tmp
                //     };
                // }

                mailboxes
                    .values()
                    .filter(|x| !x.no_select)
                    .cloned()
                    .collect::<Vec<Box<melib::backends::imap::ImapMailbox>>>()
            })
        }))
    }

    fn sync_folders(&self) -> ResultFuture<()> {
        let fetch_folders_job = self.fetch_folders();
        let store_clone = self.store.clone();
        let bare_identity_clone = self.bare_identity.clone();

        Ok(Box::pin(async move {
            let mailboxes = fetch_folders_job?.await?; //@TODO rename to fetch mailboxes

            // This is used to detect local folders removed from the server
            let mut leftover_folders_store: HashMap<_, _> = store_clone
                .get_folders(&bare_identity_clone)?
                .into_iter()
                .map(|folder| (folder.folder_path.clone(), folder))
                .collect();

            for mailbox_value in mailboxes.iter() {
                let mailbox_path = mailbox_value.path().to_string();

                match leftover_folders_store.get(&mailbox_path) {
                    Some(_) => {
                        debug!(
                            "Found folder {} locally for identity {}. Removing from leftover set",
                            &mailbox_path, &bare_identity_clone.email_address
                        );
                        leftover_folders_store.remove(&mailbox_path);
                    }
                    None => {
                        debug!(
                            "Did not find folder {} locally for identity {}. Inserting in database",
                            &mailbox_path, &bare_identity_clone.email_address
                        );
                        store_clone.store_folder_for_mailbox(&bare_identity_clone, &mailbox_value)?;
                    }
                }
            }

            for (folder_path, folder_value) in leftover_folders_store.iter() {
                debug!(
                    "Detected that folder {} for identity {} is not on the server. Removing from database",
                    &folder_path, &bare_identity_clone.email_address
                );
                store_clone.remove_folder(&bare_identity_clone, &folder_value)?;
            }

            //@TODO trigger application event to reload folders

            Ok(())
        }))
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

    fn sync_messages_for_folder(&self, folder: &models::Folder, sync_type: SyncType) -> ResultFuture<()> {
        let folder_clone = folder.clone();
        let store_clone = self.store.clone();

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

        let sync_job = self
            .backend
            .read()
            .unwrap()
            .sync(folder.folder_path.clone(), backend_sync_type.clone())
            .unwrap();

        let online_job = self
            .backend
            .read()
            .map_err(|e| e.to_string())?
            .is_online()
            .map_err(|e| e.to_string())?;

        Ok(Box::pin(async move {
            debug!("Syncing messages for folder {}, checking if online", folder_clone.folder_name);

            online_job.await.map_err(|e| e.to_string())?;

            debug!("Online, syncing");
            let (new_uid_validity, mut new_messages, flag_updates) = sync_job.await.map_err(|e| e.to_string())?;

            // @TODO asyncstream while let Some(bla) = x.next().await { }

            debug!("Saving fetched data to store");

            let now = Instant::now();

            match backend_sync_type {
                imap::SyncType::Fresh => {
                    store_clone.store_messages_for_folder(&mut new_messages, &folder_clone, Some(new_uid_validity))?;
                }
                imap::SyncType::Update {
                    max_uid: _,
                    uid_validity: current_uid_validity,
                } => {
                    if new_uid_validity == current_uid_validity {
                        store_clone.store_messages_for_folder(&mut new_messages, &folder_clone, None)?;

                        if let Some(flag_updates) = flag_updates {
                            //@TODO
                            for flag_update in flag_updates.iter() {
                                debug!("{}", flag_update.uid);
                            }
                        }
                        //@TODO 2) find out which old messages got expunged; and
                    } else {
                        //@TODO delete all mail
                        //@todo store
                        //@TODO set new uid_validity on folder
                    }
                }
            };

            debug!("Finished saving data. Took {} seconds.", now.elapsed().as_millis() as f32 / 1000.0);

            Ok(())
        }))
    }

    pub fn is_message_content_downloaded(&self, conversation_id: i32) -> Result<bool, String> {
        self.store.is_message_content_downloaded(conversation_id)
    }

    pub async fn fetch_message_content(&self, conversation_id: i32) -> Result<(), String> {
        self.fetch_message_content_inner(conversation_id)?.await
    }

    fn fetch_message_content_inner(&self, conversation_id: i32) -> ResultFuture<()> {
        let store_clone = self.store.clone();

        //@TODO handle case when this returns error
        let message = self.store.get_message(conversation_id).expect("Unable to get message");
        let folder = self.store.get_folder(message.folder_id).expect("Unable to get folder");

        let fetch_message_content_job = self
            .backend
            .read()
            .unwrap()
            .fetch_message_content(&folder.folder_path, message.uid)
            .unwrap();

        let online_job = self
            .backend
            .read()
            .map_err(|e| e.to_string())?
            .is_online()
            .map_err(|e| e.to_string())?;

        Ok(Box::pin(async move {
            debug!(
                "Fetching content for message uid {} in folder {}, checking if online",
                message.uid, &folder.folder_path
            );

            online_job.await.map_err(|e| e.to_string())?;

            debug!("Online, fetching");

            let message_content = fetch_message_content_job.await.map_err(|e| e.to_string())?;

            store_clone.store_content_for_message(message_content, &message)?;

            Ok(())
        }))
    }

    pub fn get_folders(&self) -> Result<Vec<models::Folder>, String> {
        self.store.get_folders(&self.bare_identity)
    }

    pub fn get_conversations_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::Message>, String> {
        self.store.get_messages_for_folder(folder)
    }

    // fn start_listening_for_updates(&self) {
    //     let mailboxes_job = self.backend.read().unwrap().mailboxes().unwrap();
    //     let watch_job = self.backend.read().unwrap().watch().unwrap();

    //     let online_job = self.backend.read().unwrap().is_online().unwrap();
    //     let context = glib::MainContext::default();

    //     context.spawn(online_job.and_then(|_| mailboxes_job).and_then(|_|
    // watch_job).map(move |_| ())); }
}
