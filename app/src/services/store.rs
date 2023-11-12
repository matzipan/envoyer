use crate::backends;
use crate::config::PROFILE;
use crate::controllers::ApplicationProfile;
use crate::models;
use crate::schema;

// Normally the store should be melib-agnostic, but we're adding it in for the
// moment for simplicity
use melib::BackendMailbox;

use log::debug;
use std::collections::{HashMap, HashSet};
use std::convert::TryFrom;
use std::env;
use std::fmt;

use diesel::prelude::*;

use diesel::migration::MigrationConnection;
use diesel_migrations::MigrationHarness;

pub const MIGRATIONS: diesel_migrations::EmbeddedMigrations = diesel_migrations::embed_migrations!();

pub enum StoreType {
    Fresh { new_uid_validity: u32 },
    Incremental,
}

pub struct Store {
    pub database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::SqliteConnection>>,
}

impl fmt::Debug for Store {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Store").finish()
    }
}

fn get_database_path() -> Option<String> {
    fn allow_only_absolute(path: std::path::PathBuf) -> Option<std::path::PathBuf> {
        if path.is_absolute() {
            Some(path)
        } else {
            None
        }
    }

    env::var("XDG_DATA_HOME")
        .ok()
        .map(std::path::PathBuf::from)
        .and_then(allow_only_absolute)
        .or_else(|| {
            env::var("HOME")
                .ok()
                .map(std::path::PathBuf::from)
                .and_then(allow_only_absolute)
                .map(|path| path.join(".local/share"))
        })
        .map(|path| match PROFILE {
            ApplicationProfile::Default => path.join("db.sqlite"),
            ApplicationProfile::Devel => path.join("db-devel.sqlite"),
        })
        .map(|path| path.into_os_string().into_string().unwrap())
}

impl Store {
    pub fn new() -> Store {
        let database_path = get_database_path().expect("Unable to determine where to store the database");
        debug!("Using database path {}", database_path);

        let database_connection_manager = diesel::r2d2::ConnectionManager::<diesel::sqlite::SqliteConnection>::new(database_path);
        let database_connection_pool = diesel::r2d2::Pool::builder().build(database_connection_manager).unwrap();

        debug!("Created database connection pool");

        Store { database_connection_pool }
    }

    pub fn initialize_database(&self) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        debug!("Set up the migrations table");

        connection.setup().map_err(|e| e.to_string())?;

        connection.run_pending_migrations(MIGRATIONS).map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn is_account_setup_needed(&self) -> bool {
        let connection = &mut self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        let identities: i64 = schema::identities::table
            .select(diesel::dsl::count_star())
            .first(connection)
            .expect("Unable to get the number of identities");

        identities == 0
    }

    pub fn store_bare_identity(&self, new_bare_identity: &models::NewBareIdentity) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        diesel::insert_into(schema::identities::table)
            .values(new_bare_identity)
            .execute(connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn get_bare_identities(&self) -> Result<Vec<models::BareIdentity>, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::identities::table
            .load::<models::BareIdentity>(connection)
            .map_err(|e| e.to_string())
    }

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

        let connection = &mut self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        debug!(
            "Storing folder {} for identity {}",
            &new_folder.folder_path, &bare_identity.email_address
        );

        diesel::insert_into(schema::folders::table)
            .values(&new_folder)
            .execute(connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn remove_folder(&self, bare_identity: &models::BareIdentity, folder: &models::Folder) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        debug!(
            "Removing folder {} for identity {}",
            &folder.folder_name, &bare_identity.email_address
        );

        diesel::delete(folder).execute(connection).map_err(|e| e.to_string())?;

        //@TODO remove messages belonging to the folder

        Ok(())
    }

    pub fn get_folders(&self, bare_identity: &models::BareIdentity) -> Result<Vec<models::Folder>, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::folders::table
            .filter(schema::folders::identity_id.eq(bare_identity.id))
            .load::<models::Folder>(connection)
            .map_err(|e| e.to_string())
    }

    /// Gets the maximum UID for a folder and its UID validity number.
    ///
    /// It returns `Ok(None)` when the folder exists but has not messages
    /// inside or when the folder has not been synchronized yet.
    ///
    /// # Arguments
    ///
    /// * `folder` - The folder for which to get the values for.
    ///
    /// # Errors
    ///
    /// * When the folder does not exist in the database
    /// * Other errors
    pub fn get_max_uid_and_uid_validity_for_folder(
        &self,
        folder: &models::Folder,
    ) -> Result<Option<(melib::backends::imap::UID, melib::backends::imap::UID)>, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::folders::table
            .select(schema::folders::uid_validity)
            .filter(schema::folders::id.eq(folder.id))
            .first::<Option<i64>>(connection)
            .map_err(|e| e.to_string())
            .and_then(|uid_validity| {
                match uid_validity {
                    None => Ok(None),
                    Some(uid_validity) => {
                        // We have to store it as i64 since SQLite doesn't have unsigned data_types.
                        // It's not clear from the RFC what data type to use for uid_validity, but I've
                        // seen other implementations use u32. Therefore, we're safe to do this
                        // transformation and not worry about errors.
                        let uid_validity = melib::backends::imap::UID::try_from(uid_validity).unwrap();

                        match schema::messages::table
                            .select(diesel::dsl::max(schema::messages::uid))
                            .filter(schema::messages::folder_id.eq(folder.id))
                            .first::<Option<i64>>(connection)
                        {
                            Ok(Some(max_uid)) => {
                                // max_uid is u32 according th the IMAP RFC but we're storing it as i64 since
                                // SQLite doesn't have unsigned data_types. Therefore, we're
                                // safe to do this transformation and not worry about any errors.
                                let max_uid = melib::backends::imap::UID::try_from(max_uid).unwrap();

                                Ok(Some((max_uid, uid_validity)))
                            }
                            Ok(None) => Ok(None),
                            Err(diesel::NotFound) => Ok(None),
                            Err(e) => Err(e.to_string()),
                        }
                    }
                }
            })
    }

    pub fn get_message_count_for_folder(&self, folder: &models::Folder) -> Result<u32, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .filter(schema::messages::folder_id.eq(folder.id))
            .count()
            .get_result(connection)
            // The gtk libraries accept u32, so we don't keep the full range
            .map(|x: i64| x as u32)
            .map_err(|e| e.to_string())
    }

    pub fn get_folder(&self, id: i32) -> Result<models::Folder, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::folders::table
            .filter(schema::folders::id.eq(id))
            .first::<models::Folder>(connection)
            .map_err(|e| e.to_string())
    }

    pub fn get_message(&self, id: i32) -> Result<models::Message, String> {
        let connection: &mut diesel::r2d2::PooledConnection<diesel::r2d2::ConnectionManager<SqliteConnection>> =
            &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .filter(schema::messages::id.eq(id))
            .first::<models::Message>(connection)
            .map_err(|e| e.to_string())
    }

    pub fn get_message_summary(&self, id: i32) -> Result<models::MessageSummary, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .select((
                schema::messages::id,
                schema::messages::message_id,
                schema::messages::subject,
                schema::messages::from,
                schema::messages::time_received,
            ))
            .filter(schema::messages::id.eq(id))
            .first::<models::MessageSummary>(connection)
            .map_err(|e| e.to_string())
    }

    pub fn get_messages_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::Message>, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .filter(schema::messages::folder_id.eq(folder.id))
            .order(schema::messages::time_received.desc())
            .load::<models::Message>(connection)
            .map_err(|e| e.to_string())
    }

    pub fn get_message_summaries_for_folder(&self, folder: &models::Folder) -> Result<Vec<models::MessageSummary>, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .select((
                schema::messages::id,
                schema::messages::message_id,
                schema::messages::subject,
                schema::messages::from,
                schema::messages::time_received,
            ))
            .filter(schema::messages::folder_id.eq(folder.id))
            .order(schema::messages::time_received.desc())
            .load::<models::MessageSummary>(connection)
            .map_err(|e| e.to_string())
    }

    /// Stores a vector of new messages for a folder
    ///
    /// # Arguments
    ///
    /// * `new_messages` - The messages to store. After inserting, each message
    ///   will have its id field populated with the unique ID of the inserted
    ///   row in the database.
    /// * `folder` - The folder to save for
    /// * `store_type` - A fresh update deletes the existing messages in the
    ///   folder and sets the value of uid_validity for this folder.
    pub fn store_messages_for_folder(
        &self,
        new_messages: &mut Vec<models::NewMessage>,
        folder: &models::Folder,
        store_type: StoreType,
    ) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        connection
            .transaction::<(), diesel::result::Error, _>(|connection| {
                match store_type {
                    StoreType::Fresh { new_uid_validity } => {
                        debug!("Doing store messages of type fresh with new UID validity {}", new_uid_validity);

                        diesel::delete(schema::messages::table)
                            .filter(schema::messages::folder_id.eq(folder.id))
                            .execute(connection)?;

                        diesel::update(folder)
                            .set(schema::folders::uid_validity.eq(Some(new_uid_validity as i64)))
                            .execute(connection)?;
                    }
                    StoreType::Incremental => {}
                };

                for new_message in new_messages.iter_mut() {
                    new_message.folder_id = folder.id;

                    let non_mut_new_message: &models::NewMessage = new_message;

                    let id = diesel::insert_into(schema::messages::table)
                        .values(non_mut_new_message)
                        .returning(schema::messages::id)
                        .get_result::<i32>(connection)?;

                    new_message.id = Some(id);
                }

                Ok(())
            })
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Stores a vector of message flag updates for a folder
    ///
    /// # Arguments
    ///
    /// * `flag_updates` - The flag updates to store
    pub fn store_message_flag_updates_for_folder(&self, flag_updates: &Vec<backends::imap::MessageFlagUpdate>) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        connection
            .transaction::<(), diesel::result::Error, _>(|connection| {
                for flag_update in flag_updates.iter() {
                    diesel::update(schema::messages::table)
                        .filter(schema::messages::uid.eq(flag_update.uid as i64))
                        .set(flag_update.flags.clone())
                        .execute(connection)?;
                }

                Ok(())
            })
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Removes from the store UIDs that do not belong to the set
    ///
    /// # Arguments
    ///
    /// * `server_uid_set` - A hash set containing the UIDs that should be kept
    ///   in the database
    /// * `folder` - The folder to filter the UIDs for
    pub fn keep_only_uids_for_folder(
        &self,
        server_uid_set: &HashSet<melib::backends::imap::UID>,
        folder: &models::Folder,
    ) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        // The key is the UID and the value is the database primary key
        let mut store_folder_uids: HashMap<_, _> = schema::messages::table
            .select((schema::messages::uid, schema::messages::id))
            .filter(schema::messages::folder_id.eq(folder.id))
            .load::<(i64, i32)>(connection)
            .map_err(|e| e.to_string())?
            .into_iter()
            .collect();

        debug!(
            "Total in store: {}. Total on server: {}",
            store_folder_uids.len(),
            server_uid_set.len(),
        );

        let ids_not_on_server: Vec<_> = store_folder_uids
            .into_iter()
            .filter(|(uid, _)| !server_uid_set.contains(&(*uid as u32)))
            .map(|(_, id)| id)
            .collect();

        debug!(
            "Keys not on server {:?}. Total not on server: {}",
            ids_not_on_server,
            ids_not_on_server.len()
        );

        diesel::delete(schema::messages::table)
            .filter(schema::messages::id.eq_any(ids_not_on_server))
            .execute(connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn store_content_for_message(&self, message_content: String, message: &models::Message) -> Result<(), String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        diesel::update(message)
            .set(schema::messages::content.eq(&message_content))
            .execute(connection)
            .map_err(|e| e.to_string())?;

        Ok(())
    }

    pub fn is_message_content_downloaded(&self, id: i32) -> Result<bool, String> {
        let connection = &mut self.database_connection_pool.get().map_err(|e| e.to_string())?;

        schema::messages::table
            .select(diesel::dsl::count_star())
            .filter(schema::messages::id.eq(id))
            .filter(schema::messages::content.is_not_null())
            .first(connection)
            .map(|x: i64| x == 1)
            .map_err(|e| e.to_string())
    }
}
