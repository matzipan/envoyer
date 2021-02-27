use diesel::prelude::*;
use futures::prelude::*;

use log::{debug, error, info};

use gtk::glib;

use melib::backends::{BackendMailbox, SpecialUsageMailbox};
use melib::{AccountSettings, BackendEventConsumer};

use std::boxed::Box;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::pin::Pin;
use std::sync::{Arc, RwLock};

use async_stream;

use crate::google_oauth;
use crate::imap;
use crate::models;
use crate::schema;

pub type ResultFuture<T> = Result<Pin<Box<dyn Future<Output = Result<T, String>> + Send + 'static>>, String>;

pub struct Store {
    database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::SqliteConnection>>,
}

pub enum SyncType {
    Fresh,
    Update,
}

impl Store {
    //@TODO spawn database interactions to a different thread and then join await? maybe async_thread library works for this
    pub fn store_folder_for_mailbox(
        &self,
        bare_identity: &models::BareIdentity,
        mailbox: &melib::backends::imap::ImapMailbox,
    ) -> Result<(), String> {
        let new_folder = models::NewFolder {
            folder_name: mailbox.name().to_string(),
            folder_path: mailbox.path().to_string(),
            //@TODO uid_validity, after this uid_validity might not have to be Option anymore
            identity_id: bare_identity.id,
            flags: 0, //@TODO flags
        };

        let connection = self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        debug!(
            "Storing folder {} for identity {}",
            &new_folder.folder_path, &bare_identity.email_address
        );

        diesel::insert_into(schema::folders::table)
            .values(&new_folder)
            .execute(&connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn remove_folder(&self, bare_identity: &models::BareIdentity, folder: &models::Folder) -> Result<(), String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        debug!(
            "Removing folder {} for identity {}",
            &folder.folder_name, &bare_identity.email_address
        );

        diesel::delete(folder).execute(&connection).map_err(|e| e.to_string())?;

        //@TODO remove messages belonging to the folder

        Ok(())
    }

    pub fn get_folders(&self, bare_identity: &models::BareIdentity) -> Result<Vec<models::Folder>, String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::folders::table
            .filter(schema::folders::identity_id.eq(bare_identity.id))
            .load::<models::Folder>(&connection)
            .map_err(|e| e.to_string())
    }

    pub fn get_max_uid_and_uid_validity_for_folder(
        &self,
        folder: &models::Folder,
    ) -> Result<Option<(melib::backends::imap::UID, melib::backends::imap::UID)>, String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        match schema::messages::table
            .select(diesel::dsl::max(schema::messages::uid))
            .filter(schema::messages::folder_id.eq(folder.id))
            .first::<Option<i64>>(&connection)
        {
            Ok(Some(x)) => {
                let max_uid = x;

                // max_uid is u32 according th the IMAP RFC but we're storing it as i64 since SQLite doesn't have unsigned
                // data_types. Therefore, we're safe to do this transformation and not worry about any errors.
                let max_uid = melib::backends::imap::UID::try_from(max_uid).unwrap();

                let uid_validity = 0; //@TODO

                Ok(Some((max_uid, uid_validity)))
            }
            Ok(None) => Ok(None),
            Err(diesel::NotFound) => Ok(None),
            Err(e) => Err(e.to_string()),
        }
    }

    pub fn get_messages_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::Message>, String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .filter(schema::messages::folder_id.eq(folder.id))
            .load::<models::Message>(&connection)
            .map_err(|e| e.to_string())
    }

    pub fn store_message_for_folder(&self, new_message: &mut models::NewMessage, folder: &models::Folder) -> Result<(), String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        new_message.folder_id = folder.id;

        let non_mut_new_message: &models::NewMessage = new_message;

        diesel::insert_into(schema::messages::table)
            .values(non_mut_new_message)
            .execute(&connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }
}

#[derive(Clone)]
pub struct Identity {
    bare_identity: Arc<models::BareIdentity>,
    backend: Arc<RwLock<Box<imap::ImapBackend>>>,
    store: Arc<Store>,
}

impl Identity {
    pub async fn new(
        bare_identity: models::BareIdentity,
        database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::SqliteConnection>>,
    ) -> Identity {
        info!("Creating identity with address {}", bare_identity.email_address);
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
            store: Arc::new(Store { database_connection_pool }),
        };
    }

    pub async fn initialize(&self) -> Result<(), String> {
        info!("Initializing identity with address {}", self.bare_identity.email_address);

        //@TODO how does LSUB come into play/ only filter for subscribed?
        self.sync_folders()?.await?;

        for folder in self.store.get_folders(&self.bare_identity)? {
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
            sync_folder_job.await;
            sync_messages_for_index_job.await;
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
            mailboxes_job.await.map_err(|e| e.to_string()).map(|mut mailboxes| {
                // for mailbox in mailboxes.values_mut() {
                //     //@TODO
                //     let mailbox_usage = if mailbox.special_usage() != SpecialUsageMailbox::Normal {
                //         Some(mailbox.special_usage())
                //     } else {
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
    // ) -> Result<Pin<Box<dyn Stream<Item = Result<melib::email::Mail, melib::error::MeliError>>>>, String> {
    //     // if let Ok(mut mailbox_job) = backend.fetch(inbox.hash()) {

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
    //     //     //         let operation = backend_clone.read().unwrap().operation(envelope.hash()).unwrap();
    //     //     //         // yield String::from_utf8(operation.as_bytes().unwrap().await.unwrap());
    //     //     //         yield melib::email::Mail::new(operation.as_bytes().unwrap().await.unwrap(), None);
    //     //     //     }
    //     //     // }

    //     //     return;
    //     // }))
    // }

    fn sync_messages_for_folder(&self, folder: &models::Folder, sync_type: SyncType) -> ResultFuture<()> {
        let store_clone = self.store.clone();
        let bare_identity_clone = self.bare_identity.clone();
        let folder_clone = folder.clone();
        let store_clone = self.store.clone();

        let backend_sync_type = match sync_type {
            SyncType::Fresh => imap::SyncType::Fresh,
            SyncType::Update => {
                if let Some((max_uid, uid_validity)) = self.store.get_max_uid_and_uid_validity_for_folder(folder)? {
                    imap::SyncType::Update {
                        max_uid: max_uid,
                        uid_validity: uid_validity,
                    }
                } else {
                    imap::SyncType::Fresh
                }
            }
        };

        let sync_job = self
            .backend
            .read()
            .unwrap()
            .sync(folder.folder_path.clone(), backend_sync_type)
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
            let (new_uid_validity, mut new_messages, mut flag_updates) = sync_job.await.map_err(|e| e.to_string())?;

            // @TODO asyncstream while let Some(bla) = x.next().await { }

            match sync_type {
                SyncType::Fresh => {
                    for new_message in new_messages.iter_mut() {
                        store_clone.store_message_for_folder(new_message, &folder_clone)?;
                    }
                }
                SyncType::Update => {
                    if let Some(current_uid_validity) = store_clone.get_max_uid_and_uid_validity_for_folder(&folder_clone)? {
                        if new_uid_validity == current_uid_validity.1 {
                            for new_message in new_messages.iter_mut() {
                                store_clone.store_message_for_folder(new_message, &folder_clone)?;
                            }
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
                    } else {
                        return Err("Unable to fetch the current max uid and uid validity for the sync".to_string());
                    }
                }
            };

            Ok(())
        }))
    }

    pub fn get_folders(&self) -> Result<Vec<models::Folder>, String> {
        self.store.get_folders(&self.bare_identity)
    }

    pub fn get_threads_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::Message>, String> {
        self.store.get_messages_for_folder(folder)
    }

    // fn start_listening_for_updates(&self) {
    //     let mailboxes_job = self.backend.read().unwrap().mailboxes().unwrap();
    //     let watch_job = self.backend.read().unwrap().watch().unwrap();

    //     let online_job = self.backend.read().unwrap().is_online().unwrap();
    //     let context = glib::MainContext::default();

    //     context.spawn(online_job.and_then(|_| mailboxes_job).and_then(|_| watch_job).map(move |_| ()));
    // }
}
