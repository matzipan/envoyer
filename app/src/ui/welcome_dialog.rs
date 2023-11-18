use gtk::glib;
use gtk::prelude::*;
use gtk::subclass::prelude::*;

use adw;
use adw::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;
use crate::models;

mod imp {
    use chrono::{DateTime, Utc};
    use gtk::{glib::Properties, CompositeTemplate};
    use log::error;

    use super::*;

    #[derive(CompositeTemplate, Default)]
    #[template(resource = "/com/github/matzipan/envoyer/welcome_dialog.ui")]
    pub struct WelcomeDialog {
        pub sender: Rc<RefCell<Option<glib::Sender<ApplicationMessage>>>>,
        #[template_child]
        spinner: TemplateChild<gtk::Spinner>,
        #[template_child]
        email_address_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        full_name_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        account_name_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        imap_server_hostname_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        imap_server_port_entry: TemplateChild<adw::EntryRow>,
        #[template_child]
        imap_password_entry: TemplateChild<adw::PasswordEntryRow>,
        #[template_child]
        imap_use_tls_switch: TemplateChild<adw::SwitchRow>,
        #[template_child]
        imap_use_starttls_switch: TemplateChild<adw::SwitchRow>,
        #[template_child]
        navigation_view: TemplateChild<adw::NavigationView>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for WelcomeDialog {
        const NAME: &'static str = "WelcomeDialog";
        type Type = super::WelcomeDialog;
        type ParentType = adw::Window;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    impl ObjectImpl for WelcomeDialog {}
    impl WidgetImpl for WelcomeDialog {}
    impl WindowImpl for WelcomeDialog {}
    impl AdwWindowImpl for WelcomeDialog {}

    #[gtk::template_callbacks]
    impl WelcomeDialog {
        #[template_callback]
        fn welcome_screen_next_clicked(&self) {
            //@TODO check the values

            let email_address = self.email_address_entry.get().text().to_string();

            if email_address.ends_with("gmail.com") {
                self.navigation_view.get().push_by_tag("authorization-screen");
            } else {
                self.navigation_view.get().push_by_tag("connection-details");
            }
        }

        #[template_callback]
        fn connection_details_next_clicked(&self) {
            //@TODO check the values

            let email_address = self.email_address_entry.get().text().to_string();
            let full_name = self.full_name_entry.get().text().to_string();
            let account_name = self.account_name_entry.get().text().to_string();
            let imap_server_hostname = self.imap_server_hostname_entry.get().text().to_string();
            let imap_password = self.imap_password_entry.get().text().to_string();
            let imap_use_tls = self.imap_use_tls_switch.get().is_active();
            let imap_use_starttls = self.imap_use_starttls_switch.get().is_active();

            let imap_server_port = self.imap_server_port_entry.get().text().trim().parse::<u16>();

            if let Ok(imap_server_port) = imap_server_port {
                self.sender
                    .borrow()
                    .as_ref()
                    .expect("Message sender not available")
                    .send(ApplicationMessage::SaveIdentity {
                        email_address,
                        full_name,
                        identity_type: models::IdentityType::Imap,
                        account_name,
                        expires_at: DateTime::<Utc>::MIN_UTC,
                        imap_server_hostname,
                        imap_server_port,
                        imap_password,
                        imap_use_tls,
                        imap_use_starttls,
                        gmail_access_token: String::new(),
                        gmail_refresh_token: String::new(),
                    })
                    .map_err(|e| e.to_string())
                    .map_err(|x| error!("{}", x)); //@TODO

                self.show_please_wait();
            }
        }

        #[template_callback]
        fn authorize_clicked(&self) {
            let email_address = self.email_address_entry.get().text().to_string();
            let full_name = self.full_name_entry.get().text().to_string();
            let account_name = self.account_name_entry.get().text().to_string();

            self.sender
                .borrow()
                .as_ref()
                .expect("Message sender not available")
                .send(ApplicationMessage::OpenGoogleAuthentication {
                    email_address,
                    full_name,
                    account_name,
                })
                .expect("Unable to send application message");

            self.navigation_view.get().push_by_tag("check-browser");
        }

        pub fn show_please_wait(&self) {
            self.spinner.start();
            self.navigation_view.get().push_by_tag("please-wait");
        }
    }
}

glib::wrapper! {
    pub struct WelcomeDialog(ObjectSubclass<imp::WelcomeDialog>)
        @extends gtk::Widget, adw::Window, gtk::Window;
}

impl WelcomeDialog {
    pub fn new(sender: glib::Sender<ApplicationMessage>) -> Self {
        let window: Self = glib::Object::builder().build();

        let imp = window.imp();

        imp.sender.replace(Some(sender));

        window
    }

    pub fn show_please_wait(&self) {
        let imp = self.imp();

        imp.show_please_wait();
    }
}
