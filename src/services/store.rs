use crate::models;
use crate::schema;

// Normally the store should be melib-agnostic, but we're adding it in for the
// moment for simplicity
use melib::BackendMailbox;

use log::debug;
use std::convert::TryFrom;

use diesel::prelude::*;

pub struct Store {
    pub database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::SqliteConnection>>,
}

impl Store {
    //@TODO spawn database interactions to a different thread and then join await?
    //@TODO maybe async_thread library works for this
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

                // max_uid is u32 according th the IMAP RFC but we're storing it as i64 since
                // SQLite doesn't have unsigned data_types. Therefore, we're
                // safe to do this transformation and not worry about any errors.
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
