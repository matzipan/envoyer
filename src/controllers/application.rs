use gtk;
use gtk::gio::prelude::*;
use gtk::glib;

use chrono::prelude::*;
use futures::prelude::*;

use log::{error, info};

use crate::google_oauth;
use crate::models;
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
    ShowFolder {
        folder: models::Folder,
    },
    ShowConversation {
        conversation: models::Message,
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
    identities: Arc<Mutex<Vec<models::Identity>>>, //@TODO should probably be arc<identity>
    store: Arc<services::Store>,
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

        let identities = Arc::new(Mutex::new(Vec::<models::Identity>::new()));

        let application = Self {
            main_window: Rc::new(RefCell::new(ui::Window::new(
                gtk_application,
                application_message_sender.clone(),
                identities.clone(),
            ))),
            // Ideally this dialog would be created only if account setup is
            // needed, but to simplify reference passing right now, we're
            // always creating it.
            welcome_dialog: Rc::new(RefCell::new(ui::WelcomeDialog::new(application_message_sender.clone()))),
            application_message_sender: application_message_sender,
            context: context,
            identities: identities,
            store: Arc::new(services::Store::new()),
        };

        application.context.push_thread_default();

        let store_clone = application.store.clone();
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
                    info!("SaveIdentity for {}", email_address);

                    let new_bare_identity = models::NewBareIdentity {
                        email_address: &email_address,
                        gmail_refresh_token: &gmail_refresh_token,
                        identity_type: identity_type,
                        expires_at: &expires_at.naive_utc(),
                        full_name: &full_name,
                        account_name: &account_name,
                    };

                    let store_clone = store_clone.clone();
                    store_clone.store_bare_identity(&new_bare_identity).map_err(|x| error!("{}", x));

                    application_message_sender
                        .send(ApplicationMessage::LoadIdentities { initialize: true })
                        .expect("Unable to send application message");
                }
                ApplicationMessage::LoadIdentities { initialize } => {
                    info!("LoadIdentities with initialize {}", initialize);

                    let application_message_sender_clone = application_message_sender.clone();
                    let store_clone = store_clone.clone();
                    let identities_clone = identities_clone.clone();

                    context_clone.spawn(async move {
                        // @TODO replace the expects with error reporting
                        let bare_identities = store_clone.get_bare_identities().expect("Unable to acquire a database connection");

                        for bare_identity in bare_identities {
                            let store_clone = store_clone.clone();

                            let identity = models::Identity::new(bare_identity, store_clone).await;

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
                    let folders = identity.get_folders().expect("BLA");

                    main_window.borrow().load_conversations(conversations);
                    main_window.borrow().load_folders(folders);

                    welcome_dialog.borrow().hide();
                    main_window.borrow().show();
                }
                ApplicationMessage::ShowFolder { folder } => {
                    //@TODO hacky just to get things going
                    let identity = &identities_clone.lock().expect("BLA")[0];

                    let conversations = identity.get_conversations_for_folder(&folder).expect("BLA");

                    main_window.borrow().load_conversations(conversations);
                }
                ApplicationMessage::ShowConversation { conversation } => {
                    main_window.borrow().show_conversation(conversation);
                }
                ApplicationMessage::OpenGoogleAuthentication {
                    email_address,
                    full_name,
                    account_name,
                } => {
                    let application_message_sender = application_message_sender.clone();

                    let welcome_dialog_clone = welcome_dialog.clone();

                    context_clone.spawn_local(
                        google_oauth::authenticate(email_address.clone())
                            .and_then(|authentication_result| async move {
                                let dialog_borrow_handle = welcome_dialog_clone.borrow();
                                dialog_borrow_handle.show_please_wait();
                                dialog_borrow_handle.show();

                                Ok(authentication_result)
                            })
                            .and_then(google_oauth::request_tokens)
                            .and_then(|response_token| async move {
                                application_message_sender
                                    .send(ApplicationMessage::SaveIdentity {
                                        email_address: email_address,
                                        full_name: full_name,
                                        identity_type: models::IdentityType::Gmail,
                                        account_name: account_name,
                                        gmail_access_token: response_token.access_token,
                                        gmail_refresh_token: response_token.refresh_token,
                                        expires_at: response_token.expires_at,
                                    })
                                    .map_err(|e| e.to_string())?;

                                Ok(())
                            })
                            .map(|result| {
                                match result {
                                    Err(err) => {
                                        //@TODO show in UI
                                        error!("Unable to authenticate: {}", err);
                                    }
                                    _ => {}
                                };
                            }),
                    );
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
        match self.store.initialize_database() {
            Ok(_) => {
                let application_message = match self.store.is_account_setup_needed() {
                    true => ApplicationMessage::Setup {},
                    false => ApplicationMessage::LoadIdentities { initialize: false },
                };

                self.application_message_sender
                    .send(application_message)
                    .expect("Unable to send application message");
            }
            Err(e) => {
                //@TODO show an error dialog
                error!("Error encountered when initializing the database: {}", &e);
            }
        }
    }
}
