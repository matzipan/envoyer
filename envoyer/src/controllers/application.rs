use gtk;
use gtk::gio::prelude::*;
use gtk::glib;

use chrono::prelude::*;
use diesel::prelude::*;
use futures::prelude::*;

use log::{debug, error, info};

use crate::google_oauth;
use crate::models;
use crate::schema;
use crate::services;

use crate::ui;

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

diesel_migrations::embed_migrations!();

pub enum ApplicationMessage {
    Setup {},
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
    LoadFolder {
        folder: models::Folder,
    },
    OpenGoogleAuthentication {
        email_address: String,
        full_name: String,
        account_name: String,
    },
}

pub struct Application {
    main_window: Rc<RefCell<ui::Window>>,
    welcome_dialog: Rc<RefCell<ui::WelcomeDialog>>,
    application_message_sender: glib::Sender<ApplicationMessage>,
    context: glib::MainContext,
    database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::sqlite::SqliteConnection>>,
    identities: Arc<Mutex<Vec<models::Identity>>>, //@TODO should probably be arc<identity>
}

impl Application {
    pub fn run() {
        gtk::init().expect("Failed to initialize GTK Application");

        let gtk_application = gtk::Application::new(Some("com.github.matzipan.envoyer"), Default::default());

        gtk_application.connect_startup(|gtk_application| {
            Application::on_startup(&gtk_application);
        });

        gtk_application.run();
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

        let identities = Arc::new(Mutex::new(Vec::<models::Identity>::new()));

        let application = Self {
            main_window: Rc::new(RefCell::new(ui::Window::new(gtk_application, identities.clone()))),
            // Ideally this dialog would be created only if account setup is
            // needed, but to simplify reference passing right now, we're
            // always creating it.
            welcome_dialog: Rc::new(RefCell::new(ui::WelcomeDialog::new(application_message_sender.clone()))),
            application_message_sender: application_message_sender,
            context: context,
            database_connection_pool: database_connection_pool,
            identities: identities,
        };

        application.context.push_thread_default();

        let database_connection_pool = application.database_connection_pool.clone();
        let context_clone = application.context.clone();
        let identities_clone = application.identities.clone();
        let welcome_dialog = application.welcome_dialog.clone();
        let main_window = application.main_window.clone();
        let application_message_sender = application.application_message_sender.clone();
        application_message_receiver.attach(None, move |msg| {
            match msg {
                ApplicationMessage::Setup {} => {
                    welcome_dialog.borrow().show();
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

                            let identity = models::Identity::new(bare_identity, database_connection_pool_clone).await;

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

                    let conversations = identity
                        .get_conversations_for_folder(&identity.get_folders().unwrap().iter().find(|&x| x.folder_name == "INBOX").unwrap())
                        .expect("BLA");

                    main_window.borrow().show_conversations(conversations);

                    welcome_dialog.borrow().hide();
                    main_window.borrow().show();
                }
                ApplicationMessage::LoadFolder { folder } => {
                    //@TODO hacky just to get things going
                    let identity = &identities_clone.lock().expect("BLA")[0];

                    let conversations = identity.get_conversations_for_folder(&folder).expect("BLA");

                    main_window.borrow().show_conversations(conversations);
                }
                ApplicationMessage::OpenGoogleAuthentication {
                    email_address,
                    full_name,
                    account_name,
                } => {
                    let application_message_sender = application_message_sender.clone();

                    let (authorization_code_sender, mut authorization_code_receiver) = futures::channel::mpsc::channel(1);
                    let (mut address_sender, mut address_receiver) = futures::channel::mpsc::channel(1);

                    // Actix is a bit more prententious about the way it wants to run, therefore we
                    // spin up its own thread, where we give it control. We then call stop on the
                    // server which should make it gracefully shut down and free up the thread.
                    std::thread::spawn(move || {
                        let mut system = actix_web::rt::System::new("AuthorizationCodeReceiverThread");
                        let mut receiver = services::AuthorizationCodeReceiver::new(authorization_code_sender).expect("bla");

                        address_sender.try_send(receiver.get_address());

                        system.block_on(receiver.run());
                        debug!("Authorization code receiver stopped");
                    });

                    let welcome_dialog_clone = welcome_dialog.clone();
                    context_clone.spawn_local(async move {
                        let token_receiver_address = address_receiver.next().await.unwrap(); //@TODO

                        match gio::AppInfo::launch_default_for_uri_async_future(
                            &format!(
                                "https://accounts.google.com/o/oauth2/v2/auth?scope={scope}&login_hint={email_address}&response_type=code&redirect_uri={redirect_uri}&client_id={client_id}",
                                scope = google_oauth::OAUTH_SCOPE,
                                email_address = email_address,
                                redirect_uri = token_receiver_address,
                                client_id = google_oauth::CLIENT_ID
                            ),
                            None::<&gio::AppLaunchContext>,
                        )
                        .await
                        {
                            Err(err) => error!("Unable to open URL in browser: {}", err),
                            Ok(_) => {
                                let authorization_code = authorization_code_receiver.next().await.expect("BLA"); //@TODO
                                //@TODO handle the case where error is returned because the sender is closed

                                welcome_dialog_clone.borrow().show();

                                // @TODO shutdown token receiver here

                                match google_oauth::request_tokens(authorization_code, token_receiver_address).await {
                                    Err(error) => error!("Unable to fetch : {}", error),
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
                                };
                            }
                        }
                    });
                }
            }
            // Returning false here would close the receiver and have senders
            // fail
            glib::Continue(true)
        });

        application.welcome_dialog.borrow().transient_for(&application.main_window.borrow());

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
