extern crate diesel;
extern crate diesel_migrations;
extern crate futures;

use gtk;
use gtk::gio::prelude::*;
use gtk::glib;

use chrono::prelude::*;
use diesel::prelude::*;
use futures::prelude::*;

use log::{error, info};

use crate::google_oauth;
use crate::identity;
use crate::models;
use crate::schema;

use crate::ui;

use std::sync::{Arc, Mutex};

diesel_migrations::embed_migrations!();

pub enum ApplicationMessage {
    Setup {},
    RequestGoogleRefreshTokens {
        email_address: String,
        full_name: String,
        account_name: String,
        authorization_code: String,
    },
    GoogleAuthorizationCodeReceived {
        email_address: String,
        full_name: String,
        account_name: String,
        authorization_code: String,
    },
    SaveIdentity {
        email_address: String,
        full_name: String,
        account_name: String,
        identity_type: models::IdentityType,
        gmail_access_token: String,
        gmail_refresh_token: String,
        expires_at: DateTime<Utc>,
    },
    LoadIdentities {
        initialize: bool,
    },
    SetupDone {},
}

pub struct Application {
    main_window: ui::Window,
    welcome_dialog: ui::WelcomeDialog,
    application_message_sender: glib::Sender<ApplicationMessage>,
    context: glib::MainContext,
    database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::sqlite::SqliteConnection>>,
    identities: Arc<Mutex<Vec<identity::Identity>>>, //@TODO should probably be arc<identity>
}

impl Application {
    pub fn run() {
        gtk::init().expect("Failed to initialize GTK Application");

        let gtk_application =
            gtk::Application::new(Some("com.github.matzipan.envoyer"), Default::default()).expect("Failed to initialize application");

        gtk_application.connect_startup(|gtk_application| {
            Application::on_startup(&gtk_application);
        });

        gtk_application.run(&[]);
    }

    fn on_startup(gtk_application: &gtk::Application) {
        gtk_application.connect_activate(|gtk_application| {
            let application = Application::new(gtk_application);

            application.on_activate();
        });
    }

    fn new(gtk_application: &gtk::Application) -> Application {
        let (application_message_sender, application_message_receiver) = glib::MainContext::channel(glib::PRIORITY_DEFAULT);
        let context = glib::MainContext::default();

        let database_connection_manager = diesel::r2d2::ConnectionManager::<diesel::sqlite::SqliteConnection>::new("db.sqlite");
        let database_connection_pool = diesel::r2d2::Pool::builder().build(database_connection_manager).unwrap();

        info!("Connected to the database");

        let identities = Arc::new(Mutex::new(Vec::<identity::Identity>::new()));

        let application = Self {
            main_window: ui::Window::new(gtk_application, identities.clone()),
            // Ideally this dialog would be created only if account setup is
            // needed, but to simplify reference passing right now, we're
            // always creating it.
            welcome_dialog: ui::WelcomeDialog::new(application_message_sender.clone()),
            application_message_sender: application_message_sender,
            context: context,
            database_connection_pool: database_connection_pool,
            identities: identities,
        };

        application.context.push_thread_default();

        let database_connection_pool = application.database_connection_pool.clone();
        let context_clone = application.context.clone();
        let identities_clone = application.identities.clone();
        let welcome_dialog = application.welcome_dialog.clone(); //@TODO these should be rc not clones
        let main_window = application.main_window.clone(); //@TODO these should be rc not clones
        let application_message_sender = application.application_message_sender.clone();
        application_message_receiver.attach(None, move |msg| {
            match msg {
                ApplicationMessage::Setup {} => {
                    welcome_dialog.show();
                }
                ApplicationMessage::SaveIdentity {
                    email_address,
                    full_name,
                    account_name,
                    identity_type,
                    gmail_access_token: _,
                    gmail_refresh_token,
                    expires_at,
                } => {
                    info!("CreateIdentity for {}", email_address);

                    let new_bare_identity = models::NewBareIdentity {
                        email_address: &email_address,
                        gmail_refresh_token: &gmail_refresh_token,
                        identity_type: identity_type,
                        expires_at: &expires_at.naive_utc(),
                        full_name: &full_name,
                        account_name: &account_name,
                    };

                    let connection = database_connection_pool.get().expect("Unable to acquire a database connection");
                    diesel::insert_into(schema::identities::table)
                        .values(&new_bare_identity)
                        .execute(&connection)
                        .expect("Error saving new identity");

                    application_message_sender
                        .send(ApplicationMessage::LoadIdentities { initialize: true })
                        .expect("Unable to send application message");
                }
                ApplicationMessage::GoogleAuthorizationCodeReceived {
                    email_address,
                    full_name,
                    account_name,
                    authorization_code,
                } => application_message_sender
                    .send(ApplicationMessage::RequestGoogleRefreshTokens {
                        email_address,
                        full_name,
                        account_name,
                        authorization_code,
                    })
                    .expect("Unable to send application message"),
                ApplicationMessage::RequestGoogleRefreshTokens {
                    email_address,
                    full_name,
                    account_name,
                    authorization_code,
                } => {
                    info!("RequestGoogleRefreshTokens for {}", email_address);

                    let application_message_sender = application_message_sender.clone();
                    context_clone.spawn(google_oauth::request_tokens(authorization_code).map(move |result| {
                        match result {
                            Err(error) => eprintln!("Got error: {}", error),
                            Ok(response_token) => application_message_sender
                                .send(ApplicationMessage::SaveIdentity {
                                    email_address: email_address,
                                    full_name: full_name,
                                    identity_type: models::IdentityType::Gmail,
                                    account_name: account_name,
                                    gmail_access_token: response_token.access_token,
                                    gmail_refresh_token: response_token.refresh_token,
                                    expires_at: response_token.expires_at,
                                })
                                .expect("Unable to send application message"),
                        }
                    }));
                }
                ApplicationMessage::LoadIdentities { initialize } => {
                    info!("LoadIdentities with initialize {}", initialize);

                    let application_message_sender_clone = application_message_sender.clone();
                    let database_connection_pool_clone = database_connection_pool.clone();
                    let identities_clone = identities_clone.clone();

                    context_clone.spawn(async move {
                        let connection = database_connection_pool_clone
                            .get()
                            .expect("Unable to acquire a database connection");

                        let bare_identities = schema::identities::table
                            .load::<models::BareIdentity>(&connection)
                            .expect("Unable to get identities from database");

                        for bare_identity in bare_identities {
                            let database_connection_pool_clone = database_connection_pool_clone.clone();

                            let identity = identity::Identity::new(bare_identity, database_connection_pool_clone).await;

                            if initialize {
                                identity.initialize().await.map_err(|x| error!("{}", x));
                            }

                            identities_clone.lock().expect("Unable to access identities").push(identity);
                        }

                        application_message_sender_clone
                            .send(ApplicationMessage::SetupDone {})
                            .expect("Unable to send application message");
                    });
                }
                ApplicationMessage::SetupDone {} => {
                    info!("SetupDone");

                    for identity in &*identities_clone.lock().expect("Unable to access identities") {
                        identity.start_session();
                    }

                    //@TODO hacky just to get things going
                    let identity = &identities_clone.lock().expect("BLA")[0];

                    let threads = identity
                        .get_threads_for_folder(&identity.get_folders().unwrap().iter().find(|&x| x.folder_name == "INBOX").unwrap())
                        .expect("BLA");

                    welcome_dialog.hide();
                    main_window.show();
                    main_window.load(threads);
                }
            }
            // Returning false here would close the receiver and have senders
            // fail
            glib::Continue(true)
        });

        application.welcome_dialog.transient_for(&application.main_window);

        application
    }

    fn on_activate(self) {
        match self.initialize_database() {
            Ok(_) => {
                if self.is_account_setup_needed() {
                    self.application_message_sender
                        .send(ApplicationMessage::Setup {})
                        .expect("Unable to send application message");
                } else {
                    self.application_message_sender
                        .send(ApplicationMessage::LoadIdentities { initialize: false })
                        .expect("Unable to send application message");
                }
            }
            Err(e) => {
                //@TODO show an error dialog
                error!("Error encountered when initializing the database: {}", &e);
            }
        }
    }

    fn initialize_database(&self) -> Result<(), String> {
        let connection = self.database_connection_pool.get().map_err(|e| e.to_string())?;

        info!("Set up the migrations table");
        diesel_migrations::setup_database(&connection).map_err(|e| e.to_string())?;

        if diesel_migrations::any_pending_migrations(&connection).map_err(|e| e.to_string())? {
            info!("Pending migrations found, running them");
            diesel_migrations::run_pending_migrations(&connection).map_err(|e| e.to_string())?;
        }

        Ok(())
    }

    fn is_account_setup_needed(&self) -> bool {
        let connection = self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        let identities: i64 = schema::identities::table
            .select(diesel::dsl::count_star())
            .first(&connection)
            .expect("Unable to get the number of identities");

        identities == 0
    }
}

// struct GmailOAuth2 {
//     user: String,
//     access_token: String,
// }

// impl async_imap::Authenticator for &GmailOAuth2 {
//     type Response = String;
//     #[allow(unused_variables)]
//     fn process(&mut self, _data: &[u8]) -> Self::Response {
//         format!("user={}\x01auth=Bearer {}\x01\x01", self.user, self.access_token)
//     }
// }

// async fn bla() {}

// async fn bla(user: String, access_token: String) -> async_imap::error::Result<Option<String>> {
//     info!("BLA");
//     info!("{}", &access_token);
//     let gmail_auth = GmailOAuth2 {
//         user: String::from(&user),
//         access_token: String::from(access_token),
//     };
//     let domain = "imap.gmail.com";
//     let port = 993;
//     let socket_addr = (domain, port);
//     let ssl_connector = async_native_tls::TlsConnector::new();

//     let database_connection_manager = diesel::r2d2::ConnectionManager::<diesel::sqlite::SqliteConnection>::new("db.sqlite");
//     let database_connection_pool = diesel::r2d2::Pool::builder().build(database_connection_manager).unwrap();

//     let connection = database_connection_pool.get().expect("Unable to acquire a database connection");

//     let identity = schema::identities::table
//         .filter(schema::identities::email_address.eq(&user))
//         .first::<models::Identity>(&connection)
//         .unwrap();

//     // we pass in the domain twice to check that the server's TLS certificate
//     // is valid for the domain we're connecting to
//     let client = async_imap::connect(socket_addr, domain, ssl_connector).await?;

//     let mut imap_session = match client.authenticate("XOAUTH2", &gmail_auth).await {
//         Ok(c) => c,
//         Err((e, _unauth_client)) => {
//             info!("error authenticating: {}", e);
//             return Err(e);
//         }
//     };
//     let database_connection_pool_clone = database_connection_pool.clone();

//     let directories: Vec<_> = imap_session
//         .list(None, Some("*"))
//         .await
//         .unwrap()
//         .map(move |directory| {
//             let name = directory.expect("BLA").name().to_string();

//             info!("{}", &name);

//             match models::Folder::belonging_to(&identity)
//                 .filter(schema::folders::folder_name.eq(&name))
//                 .first::<models::Folder>(&connection)
//             {
//                 Ok(_) => {}
//                 Err(diesel::NotFound) => {
//                     let new_folder = models::NewFolder {
//                         folder_name: name.clone(),
//                         identity_id: identity.id,
//                         flags: 0, //@TODO flags
//                     };

//                     diesel::insert_into(schema::folders::table)
//                         .values(&new_folder)
//                         .execute(&connection)
//                         .expect("Error saving new identity");
//                 }
//                 Err(_) => {}
//             };

//             return name;
//         })
//         .collect()
//         .await;

//     // info!("{:?}", directories);

//     match imap_session.select("INBOX").await {
//         Ok(mailbox) => info!("{}", mailbox),
//         Err(e) => info!("Error selecting INBOX: {}", e),
//     };

//     let connection = database_connection_pool.get().expect("Unable to acquire a database connection");

//     let inbox_folder = schema::folders::table
//         .filter(schema::folders::folder_name.eq("INBOX"))
//         .first::<models::Folder>(&connection)
//         .unwrap();

//     // fetch message number 1 in this mailbox, along with its RFC822 field.
//     // RFC 822 dictates the format of the body of e-mails
//     let fetch: Vec<_> = imap_session
//         .uid_fetch(&format!("1:{}", async_imap::types::Uid::MAX), "ENVELOPE")
//         .await
//         .unwrap()
//         .collect()
//         .await;

//     for message in fetch {
//         // let body = message.as_ref().unwrap().body().expect("message did not have a body!");
//         let subject = std::str::from_utf8(&message.as_ref().unwrap().envelope().unwrap().subject.unwrap())
//             .unwrap()
//             .to_string();
//         info!("{:?}", subject);
//         // let addresses = message.as_ref().unwrap().envelope().unwrap().to.as_ref().unwrap();
//         // for address in addresses {
//         // info!("{:?}", std::str::from_utf8(&address.mailbox.unwrap()));
//         // }

//         //@TODO insert in db
//     }

//     imap_session.logout().await?;

//     Ok(Some("asdasd".to_string()))
// }

// #[cfg(test)]
// mod tests {
//     use std::thread;

//     // use futures::future::FutureExt as _;
//     use futures::future::FutureExt;
//     use futures::prelude::*;

//     use log::{Level, LevelFilter, Metadata, Record};

//     struct SimpleLogger;

//     impl log::Log for SimpleLogger {
//         fn enabled(&self, metadata: &Metadata) -> bool {
//             metadata.level() <= Level::Info
//         }

//         fn log(&self, record: &Record) {
//             if self.enabled(record.metadata()) {
//                 println!("{} - {}", record.level(), record.args());
//             }
//         }

//         fn flush(&self) {}
//     }

//     static LOGGER: SimpleLogger = SimpleLogger;

//     #[test]
//     fn it_works() {
//         log::set_logger(&LOGGER)
//             .map(|()| log::set_max_level(LevelFilter::Info))
//             .expect("Unable to set up logger");
//         let context = glib::MainContext::default();

//         let main_loop = glib::MainLoop::new(Some(&context), false);

//         let main_loop_clone = main_loop.clone();
//         context.spawn(super::bla("matzipan@gmail.com".to_string(), "ya29.A0AfH6SMC4eyAZM0-_I-_wUHxGZ9JGZpGBCsUdZCGHi82ym0_XJFTJn6I4VWh5Ccc6ahoIu9AzV1lHxvDgRwUEyvnb1G37mUOhRr6wP7g5mPmAwDy-A4WT8SJvBmcIAA4g5LY1gihO_23IN-Sb98vtWjEForZvhQFQU7pDo7ZsVVI".to_string()).map(move |_| {
//             main_loop_clone.quit();
//         }));

//         main_loop.run();
//     }

//     // private async void refresh_token_loop () {
//     //     while (true) {
//     //         // Seconds to spare for refresh represents how much time before the expiry we refresh the access token
//     //         var seconds_to_spare_for_refresh = 60;
//     //         var seconds_until_refresh = (uint) (expires_at.to_unix () - (new DateTime.now_utc ()).to_unix ()) - seconds_to_spare_for_refresh;

//     //         debug ("Refresh access token for identity %s scheduled in %u seconds", to_string (), seconds_until_refresh);

//     //         //@TODO what happens if the internet is down when refresh is attempted and then when the imap/smtp sessions come back the token is still expired
//     //         yield nap (seconds_until_refresh);

//     //         do_token_refresh ();
//     //     }
//     // }

//     // private void refresh_token_if_expired () {
//     //     if (expires_at.compare (new DateTime.now_utc ()) > 0) {
//     //         debug ("Access token is still valid for identity %s, not refreshing", to_string ());
//     //         return;
//     //     }

//     //     do_token_refresh ();
//     // }

//     async fn x() {
//         let token = super::refresh_access_token(
//             "matzipan@gmail.com".to_string(),
//             "1//09oVZumo4BBTCCgYIARAAGAkSNwF-L9Ir20V9JD_rZEdeiZmuzaY6zvJ0HOsJG92XqrsqgUrvWvHoDyJ_VPhhgxvJwL0gTNSu21A".to_string(),
//         )
//         .await;
//         //@TODO remove access_token from the database

//         let x = super::fetch_messages_for_inbox("matzipan@gmail.com".to_string(), token.unwrap().access_token)
//             .await
//             .map(|envelope| {
//                 println!("{:?}", envelope);

//                 // for envelope in envelope_chunk {
//                 //     let mut operation = backend.operation(envelope.hash()).unwrap();
//                 //     println!("{:?}", String::from_utf8(operation.as_bytes().unwrap().await.unwrap()));
//                 // }
//             });
//         // let x = super::bla("matzipan@gmail.com".to_string(), token.unwrap().access_token).await;
//     }

//     #[test]
//     fn fetch_folders() {
//         log::set_logger(&LOGGER)
//             .map(|()| log::set_max_level(LevelFilter::Info))
//             .expect("Unable to set up logger");
//         let context = glib::MainContext::default();

//         let main_loop = glib::MainLoop::new(Some(&context), false);

//         let main_loop_clone = main_loop.clone();
//         context.spawn(x().map(move |_| {
//             main_loop_clone.quit();
//         }));

//         main_loop.run();
//     }
// }
