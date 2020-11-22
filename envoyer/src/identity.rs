use diesel::prelude::*;
use futures::prelude::*;

use log::info;

use melib::backends::{ImapType, SpecialUsageMailbox};
use melib::{AccountSettings, BackendEventConsumer};

use std::boxed::Box;
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::{Arc, RwLock};

use async_stream;

use crate::google_oauth;
use crate::models;
use crate::schema;

pub struct Identity {
    bare_identity: models::BareIdentity,
    backend: Arc<RwLock<Box<dyn melib::backends::MailBackend>>>,
    database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::SqliteConnection>>,
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

        let settings = AccountSettings {
            extra: [
                ("server_hostname".to_string(), "imap.gmail.com".to_string()),
                ("server_username".to_string(), bare_identity.email_address.clone()),
                ("server_password".to_string(), "blablalal".to_string()), //@TODO
                ("access_token".to_string(), access_token_response.access_token),
                ("server_port".to_string(), "993".to_string()),
                ("danger_accept_invalid_certs".to_string(), "true".to_string()),
            ]
            .iter()
            .cloned()
            .collect(),
            ..Default::default()
        };
        let backend = ImapType::new(
            &settings,
            Box::new(|_| true),
            BackendEventConsumer::new(std::sync::Arc::new(|_, _| ())),
        )
        .unwrap();
        info!("Identity for {} created", bare_identity.email_address);
        return Identity {
            bare_identity: bare_identity,
            backend: Arc::new(RwLock::new(backend)),
            database_connection_pool: database_connection_pool,
        };
    }

    pub async fn initialize(&self) {
        info!("Initializing identity with address {}", self.bare_identity.email_address);

        let mut folders = self.fetch_folders().await;
        self.store_folders(&folders).await;

        let mut inbox: Option<melib::Mailbox> = None;

        for mailbox in folders.values_mut() {
            let mailbox_usage = if mailbox.special_usage() != SpecialUsageMailbox::Normal {
                Some(mailbox.special_usage())
            } else {
                let tmp = SpecialUsageMailbox::detect_usage(mailbox.name());
                if tmp != Some(SpecialUsageMailbox::Normal) && tmp != None {
                    let _ = mailbox.set_special_usage(tmp.unwrap());
                }
                tmp
            };
            if mailbox_usage == Some(SpecialUsageMailbox::Inbox) {
                inbox = Some((*mailbox).clone());
            }
        }

        let inbox_mailbox = inbox.expect("Inbox mailbox could not be found");

        let connection = self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        //@TODO better to use hash
        let inbox_folder = schema::folders::table
            .filter(schema::folders::folder_name.eq(inbox_mailbox.name().to_string()))
            .first::<models::Folder>(&connection)
            .expect("Unable to get messages for folder");

        let mut x = self.get_messages(&inbox_mailbox).await;

        while let Some(bla) = x.next().await {
            match bla {
                Ok(x) => {
                    let mut new_message = models::NewMessage::from(x);

                    new_message.folder_id = inbox_folder.id;

                    diesel::insert_into(schema::messages::table)
                        .values(&new_message)
                        .execute(&connection)
                        .expect("Error saving new folder");
                }
                Err(_) => info!("Error"),
            };
        }

        info!("Finished identity initialization for {}", self.bare_identity.email_address);
    }

    pub async fn store_folders(&self, mailboxes: &HashMap<u64, Box<dyn melib::backends::BackendMailbox + Send + Sync>>) {
        for mailbox in mailboxes.values() {
            let new_folder = models::NewFolder {
                folder_name: mailbox.name().to_string(),
                identity_id: self.bare_identity.id,
                flags: 0, //@TODO flags
            };

            let connection = self
                .database_connection_pool
                .get()
                .expect("Unable to acquire a database connection");

            diesel::insert_into(schema::folders::table)
                .values(&new_folder)
                .execute(&connection)
                .expect("Error saving new folder");

            info!("{:?}", &mailbox);
        }
    }

    pub async fn fetch_folders(&self) -> HashMap<u64, Box<dyn melib::backends::BackendMailbox + Send + Sync>> {
        let mailboxes_job = self.backend.read().unwrap().mailboxes().unwrap();
        // if let Ok(mailboxes_job) = backend.mailboxes() {
        let online_job = self.backend.read().unwrap().is_online().unwrap();
        // if let Ok(online_job) = backend.is_online() {
        online_job.then(|_| mailboxes_job).await.unwrap()

        //@TODO transform into NewFolder
    }

    pub async fn get_messages(
        &self,
        folder: &Box<dyn melib::backends::BackendMailbox + Send + Sync>,
    ) -> Pin<Box<dyn Stream<Item = Result<melib::email::Mail, melib::error::MeliError>>>> {
        // if let Ok(mut mailbox_job) = backend.fetch(inbox.hash()) {
        let mut mailbox_job = self.backend.write().unwrap().fetch(folder.hash()).unwrap();

        let backend_clone = self.backend.clone();

        Box::pin(async_stream::stream! {
            let backend_clone = backend_clone.clone();

            while let Some(envelope_chunk) = mailbox_job.next().await {
                let envelope_chunk = envelope_chunk.unwrap();

                for envelope in envelope_chunk {
                    let operation = backend_clone.read().unwrap().operation(envelope.hash()).unwrap();
                    // yield String::from_utf8(operation.as_bytes().unwrap().await.unwrap());
                    yield melib::email::Mail::new(operation.as_bytes().unwrap().await.unwrap(), None);
                }
            }

            return;
        })
    }

    pub fn start_token_renewal_thread(&self) {
        let context = glib::MainContext::default();
    }
}
