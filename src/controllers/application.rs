use gtk::gio::{prelude::*, SimpleAction};
use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};

use chrono::prelude::*;
use futures::prelude::*;

use log::{debug, error, info};

use gettextrs::gettext;

use crate::config::{APP_ID, PKGDATADIR, PROFILE, VERSION};

use crate::google_oauth;
use crate::models::{self, NewMessage};
use crate::services;

use crate::ui;

use std::cell::RefCell;
use std::rc::Rc;

#[derive(Debug)]
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
        conversation: models::MessageSummary,
    },
    ConversationContentLoadFinished {
        conversation: models::MessageSummary,
    },
    NewMessages {
        new_messages: Vec<models::NewMessage>,
        folder: models::Folder,
        identity: Rc<models::Identity>,
    },
    OpenGoogleAuthentication {
        email_address: String,
        full_name: String,
        account_name: String,
    },
    ShowConversationContainingEmail {
        email_id: i32,
    },
}

fn send_notification(notifications_email_count: &Rc<RefCell<i32>>, new_messages: Vec<NewMessage>, application_obj: &Application) {
    let count = {
        let mut count_borrow = notifications_email_count.borrow_mut();

        let new_count = *count_borrow + new_messages.len() as i32;

        *count_borrow = new_count;

        new_count
    };

    if count == 1 {
        let new_message = &new_messages[0];

        let notification = gio::Notification::new(&new_message.from);
        notification.set_body(Some(&new_message.subject));
        notification.set_priority(gio::NotificationPriority::Normal);
        notification.set_default_action_and_target_value(
            "app.show-conversation-for-email-id",
            Some(&new_message.id.expect("The message is is not set").to_variant()),
        );
        application_obj.send_notification(Some("email.arrived"), &notification);
    } else if count > 1 {
        let body_string = format!("{} new emails received", count);
        let notification = gio::Notification::new("Envoyer");
        notification.set_body(Some(&body_string));
        notification.set_priority(gio::NotificationPriority::Normal);
        application_obj.send_notification(Some("email.arrived"), &notification);
    }
}

mod imp {
    use super::*;

    #[derive(Debug, Default)]
    pub struct Application {
        pub main_window: RefCell<Option<ui::Window>>,
        pub application_message_sender: RefCell<Option<glib::Sender<ApplicationMessage>>>,
        pub store: RefCell<Option<Rc<services::Store>>>,
        pub notifications_email_count: Rc<RefCell<i32>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for Application {
        const NAME: &'static str = "Application";
        type Type = super::Application;
        type ParentType = gtk::Application;
    }

    impl ObjectImpl for Application {}

    impl ApplicationImpl for Application {
        fn activate(&self) {
            debug!("Application activate");

            {
                let store_borrow = self.store.borrow();
                let store = store_borrow.as_ref().expect("Unable to access store");
                match store.initialize_database() {
                    Ok(_) => {
                        let application_message = match store.is_account_setup_needed() {
                            true => ApplicationMessage::Setup {},
                            false => ApplicationMessage::LoadIdentities { initialize: false },
                        };

                        self.application_message_sender
                            .borrow()
                            .as_ref()
                            .expect("Unable to access application message sender")
                            .send(application_message)
                            .expect("Unable to send application message");
                    }
                    Err(e) => {
                        //@TODO show an error dialog
                        error!("Error encountered when initializing the database: {}", &e);
                    }
                }
            }

            self.parent_activate();

            let main_window_borrow = self.main_window.borrow();

            main_window_borrow
                .as_ref()
                .expect("Unable to access main window")
                .present_with_time((glib::monotonic_time() / 1000) as u32);
        }

        fn startup(&self) {
            debug!("Application startup");
            self.parent_startup();
            let app = self.obj();

            // Set icons for shell
            gtk::Window::set_default_icon_name(APP_ID);

            app.setup_css();
            app.setup_gactions();
            app.setup_accels();

            self.run();
        }
    }

    impl GtkApplicationImpl for Application {}

    impl Application {
        fn run(&self) {
            let (application_message_sender, application_message_receiver) = glib::MainContext::channel(glib::Priority::DEFAULT);
            let context = glib::MainContext::default();

            let folders_list_model = models::folders_list::model::FolderListModel::new();
            let conversations_list_model = models::folder_conversations_list::model::FolderModel::new();
            let conversation_model = models::conversation_messages_list::model::ConversationModel::new();

            let current_conversation_id: Rc<RefCell<Option<i32>>> = Default::default();

            *self.store.borrow_mut() = Some(Rc::new(services::Store::new()));

            let application_obj: glib::BorrowedObject<super::Application> = self.obj();

            *self.main_window.borrow_mut() = Some(ui::Window::new(
                application_obj.as_ref(),
                application_message_sender.clone(),
                &folders_list_model,
                &conversations_list_model,
                &conversation_model,
            ));

            *self.application_message_sender.borrow_mut() = Some(application_message_sender.clone());
            let application_message_sender_clone = application_message_sender.clone();

            // Ideally this dialog would be created only if account setup is needed, but to
            // simplify reference passing right now, we're always creating it.
            let welcome_dialog = ui::WelcomeDialog::new(application_message_sender.clone());
            let identities: Rc<RefCell<Vec<Rc<models::Identity>>>> = Default::default();

            let application_obj_clone = application_obj.clone();

            let context_clone = context.clone();
            let identities_clone = identities.clone();
            let current_conversation_id_clone = current_conversation_id.clone();
            let welcome_dialog_clone = welcome_dialog.clone();
            let main_window_clone = self.main_window.clone();
            let folders_list_model_clone = folders_list_model.clone();
            let conversations_list_model_clone = conversations_list_model.clone();
            let conversation_model_clone = conversation_model.clone();
            let notifications_email_count_clone = self.notifications_email_count.clone();

            let store_clone = self.store.borrow().as_ref().expect("Unable to access store").clone();

            conversations_list_model.attach_store(store_clone.clone());
            conversation_model.attach_store(store_clone.clone());
            folders_list_model.attach_store(store_clone.clone());

            application_message_receiver.attach(None, move |msg| {
                match msg {
                    ApplicationMessage::Setup {} => {
                        info!("Setup");
                        main_window_clone.borrow().as_ref().expect("Unable to access main window").hide();
                        welcome_dialog_clone.show();
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

                        context_clone.spawn_local(async move {
                            // @TODO replace the expects with error reporting
                            let bare_identities = store_clone.get_bare_identities().expect("Unable to acquire a database connection");

                            for bare_identity in bare_identities {
                                let store_clone = store_clone.clone();

                                let identity = Rc::new(
                                    models::Identity::new(bare_identity, store_clone, application_message_sender_clone.clone()).await,
                                );

                                if initialize {
                                    identity.clone().initialize().await.map_err(|x| error!("{}", x));
                                }

                                let mut identities_borrow = RefCell::borrow_mut(&identities_clone);

                                identities_borrow.push(identity);
                            }

                            application_message_sender_clone
                                .send(ApplicationMessage::SetupDone {})
                                .expect("Unable to send application message");
                        });
                    }
                    ApplicationMessage::SetupDone {} => {
                        info!("SetupDone");

                        let application_message_sender_clone = application_message_sender.clone();

                        let identities_borrow = RefCell::borrow(&identities_clone);
                        let identities: &Vec<Rc<models::Identity>> = identities_borrow.as_ref();

                        for identity in identities {
                            let identity = identity.clone();
                            context_clone.spawn_local(identity.start_session());
                        }

                        folders_list_model_clone.load();

                        let identity = identities[0].clone();

                        application_message_sender_clone
                            .send(ApplicationMessage::ShowFolder {
                                folder: identity
                                    .get_folders()
                                    .unwrap()
                                    .iter()
                                    .find(|&x| x.folder_name == "INBOX")
                                    .unwrap()
                                    .clone(),
                            })
                            .expect("Unable to send application message");

                        welcome_dialog_clone.hide();
                        main_window_clone.borrow().as_ref().expect("Unable to access main window").show();
                    }
                    ApplicationMessage::ShowFolder { folder } => {
                        info!("ShowFolder for folder with name {}", folder.folder_name);

                        let conversations_list_model_clone = conversations_list_model_clone.clone();

                        conversations_list_model_clone.load_folder(folder);
                    }
                    ApplicationMessage::ShowConversation { conversation } => {
                        info!("ShowConversation for conversation with id {}", conversation.id);

                        let application_message_sender = application_message_sender.clone();

                        let conversation_model_clone = conversation_model_clone.clone();

                        let is_message_content_downloaded = {
                            //@TODO hacky just to get things going
                            let identity = {
                                let identities_borrow = RefCell::borrow(&identities_clone);
                                let identities: &Vec<Rc<models::Identity>> = identities_borrow.as_ref();

                                identities[0].clone()
                            };

                            identity.is_message_content_downloaded(conversation.id)
                        };

                        current_conversation_id_clone.replace(Some(conversation.id));

                        match is_message_content_downloaded {
                            Ok(is_message_content_downloaded) => {
                                if is_message_content_downloaded {
                                    conversation_model_clone.load_message(conversation.id);
                                } else {
                                    info!("Message content not found. Triggering download.");

                                    conversation_model_clone.set_loading();

                                    let identity = {
                                        let identities_borrow = RefCell::borrow(&identities_clone);
                                        let identities: &Vec<Rc<models::Identity>> = identities_borrow.as_ref();

                                        identities[0].clone()
                                    };

                                    context_clone.spawn_local(
                                        async move {
                                            identity.fetch_message_content(conversation.id).await?;

                                            Ok(conversation)
                                        }
                                        .and_then(|conversation| async move {
                                            application_message_sender
                                                .send(ApplicationMessage::ConversationContentLoadFinished { conversation })
                                                .map_err(|x| x.to_string())?;

                                            Ok(())
                                        })
                                        .map(|result: Result<(), String>| {
                                            match result {
                                                Err(err) => {
                                                    //@TODO show in UI
                                                    error!("Unable to fetch message content: {}", err);
                                                }
                                                _ => {}
                                            };
                                        }),
                                    );
                                }
                            }
                            Err(x) => {}
                        }
                    }
                    ApplicationMessage::ConversationContentLoadFinished { conversation } => {
                        info!("ConversationContentLoadFinished for conversation with id {}", conversation.id);

                        // We check to see if the currently open conversation matches the conversation
                        // whose content just finished loading so that we can update the UI

                        if current_conversation_id_clone.borrow().as_ref() == Some(&conversation.id) {
                            conversation_model_clone.load_message(conversation.id);
                        }
                    }
                    ApplicationMessage::ShowConversationContainingEmail { email_id } => {
                        info!("ShowConversationContainingEmail for email with id {}", email_id);

                        let store_clone = store_clone.clone();

                        {
                            let main_window_borrow = main_window_clone.borrow();

                            // Seems broken due to https://gitlab.gnome.org/GNOME/gtk/-/issues/5239
                            main_window_borrow.as_ref().expect("Unable to access main window").present();
                        }

                        let _ = store_clone
                            .get_message_summary(email_id)
                            .map(|conversation| {
                                // @TODO for the time being conversation and email are equivalent

                                application_message_sender
                                    .send(ApplicationMessage::ShowConversation { conversation })
                                    .expect("Unable to send application message");
                            })
                            .map_err(|err| {
                                error!("Could not find message summary: {}", err);
                            });
                    }

                    ApplicationMessage::OpenGoogleAuthentication {
                        email_address,
                        full_name,
                        account_name,
                    } => {
                        info!("OpenGoogleAuthentication for {}", email_address);

                        let application_message_sender = application_message_sender.clone();

                        let welcome_dialog_clone = welcome_dialog_clone.clone();

                        context_clone.spawn_local(
                            google_oauth::authenticate(email_address.clone())
                                .and_then(|authentication_result| async move {
                                    welcome_dialog_clone.show_please_wait();
                                    welcome_dialog_clone.show();

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
                    ApplicationMessage::NewMessages {
                        new_messages,
                        folder,
                        identity,
                    } => {
                        info!(
                            "New messages received for {}: {}",
                            identity.bare_identity.email_address,
                            new_messages.len()
                        );

                        let conversations_list_model_clone = conversations_list_model_clone.clone();

                        conversations_list_model_clone.handle_new_messages_for_folder(&folder);

                        for new_message in &new_messages {
                            debug!("New message {} ", new_message.subject)
                        }

                        let is_window_active = main_window_clone.borrow().as_ref().map_or(false, |window| window.is_active());
                        let is_message_for_inbox = folder.folder_name == "INBOX";

                        if is_window_active && is_message_for_inbox {
                            send_notification(&notifications_email_count_clone, new_messages, &application_obj_clone);
                        }
                    }
                }
                // Returning false here would close the receiver and have senders fail
                glib::Continue(true)
            });

            let main_window_borrow = self.main_window.borrow();
            let main_window = main_window_borrow.as_ref().expect("Unable to access main window");

            let notifications_email_count_clone = self.notifications_email_count.clone();
            main_window.connect_is_active_notify(move |_| {
                debug!("Active detected, resetting notifications email count");
                *notifications_email_count_clone.borrow_mut() = 0;
            });

            welcome_dialog.transient_for(main_window);

            let action_show_conversation_for_email_id =
                SimpleAction::new("show-conversation-for-email-id", Some(&i32::static_variant_type()));
            action_show_conversation_for_email_id.connect_activate(move |_, parameter| {
                let email_id = parameter
                    .expect("Could not get action parameter.")
                    .get::<i32>()
                    .expect("The action parameter is not of the expected type");

                debug!("Action show-conversation-for-email-id triggered for email_id {}", email_id);

                application_message_sender_clone
                    .send(ApplicationMessage::ShowConversationContainingEmail { email_id })
                    .expect("Unable to send application message");
            });
            application_obj.add_action(&action_show_conversation_for_email_id);
        }
    }
}

glib::wrapper! {
    pub struct Application(ObjectSubclass<imp::Application>)
        @extends gio::Application, gtk::Application,
        @implements gio::ActionMap, gio::ActionGroup;
}

impl Application {
    fn main_window(&self) -> ui::Window {
        let main_window_borrow = self.imp().main_window.borrow();
        let main_window: &ui::Window = main_window_borrow.as_ref().expect("Unable to access main window");

        main_window.clone()
    }

    fn setup_gactions(&self) {
        // Quit
        let action_quit = gio::ActionEntry::builder("quit")
            .activate(move |app: &Self, _, _| {
                // This is needed to trigger the delete event and saving the window state
                app.main_window().close();
                app.quit();
            })
            .build();

        // About
        let action_about = gio::ActionEntry::builder("about")
            .activate(|app: &Self, _, _| {
                app.show_about_dialog();
            })
            .build();
        self.add_action_entries([action_quit, action_about]);
    }

    // Sets up keyboard shortcuts
    fn setup_accels(&self) {
        self.set_accels_for_action("app.quit", &["<Control>q"]);
        self.set_accels_for_action("window.close", &["<Control>w"]);
    }

    fn setup_css(&self) {
        let stylesheet_string = include_str!("../ui/stylesheet.css");
        let provider = gtk::CssProvider::new();
        provider.load_from_data(stylesheet_string);
        if let Some(display) = gdk::Display::default() {
            gtk::StyleContext::add_provider_for_display(&display, &provider, gtk::STYLE_PROVIDER_PRIORITY_APPLICATION);
        }
    }

    fn show_about_dialog(&self) {
        let dialog = gtk::AboutDialog::builder()
            .logo_icon_name(APP_ID)
            .license_type(gtk::License::Gpl30Only)
            .website("https://github.com/matzipan/envoyer/")
            .version(VERSION)
            .transient_for(&self.main_window())
            .translator_credits(gettext("translator-credits"))
            .modal(true)
            .authors(vec!["Andrei Zisu"])
            .comments("Using melib by Manos Pitsidianakis")
            .artists(vec!["Andrei Zisu"])
            .build();

        dialog.present();
    }

    pub fn run(&self) -> glib::ExitCode {
        info!("Envoyer ({})", APP_ID);
        info!("Version: {} ({})", VERSION, PROFILE);
        info!("Datadir: {}", PKGDATADIR);

        ApplicationExtManual::run(self)
    }
}

impl Default for Application {
    fn default() -> Self {
        glib::Object::builder()
            .property("application-id", APP_ID)
            .property("resource-base-path", "/com/github/matzipan/envoyer/")
            .build()
    }
}
