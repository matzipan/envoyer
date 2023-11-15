use gtk::glib;
use gtk::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;
use crate::ui;

mod imp {
    use gtk::{glib::Properties, CompositeTemplate};

    use super::*;

    #[derive(Properties, CompositeTemplate, Default)]
    #[properties(wrapper_type = super::WelcomeDialog)]
    #[template(resource = "/com/github/matzipan/envoyer/welcome_dialog.ui")]
    pub struct WelcomeDialog {
        pub sender: Rc<RefCell<Option<glib::Sender<ApplicationMessage>>>>,
        #[template_child]
        pub spinner: TemplateChild<gtk::Spinner>,
        #[template_child]
        pub stack: TemplateChild<gtk::Stack>,
        #[property(get, set)]
        pub email_address: RefCell<Option<String>>,
        #[property(get, set)]
        pub full_name: RefCell<Option<String>>,
        #[property(get, set)]
        pub account_name: RefCell<Option<String>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for WelcomeDialog {
        const NAME: &'static str = "WelcomeDialog";
        type Type = super::WelcomeDialog;
        type ParentType = gtk::Dialog;

        fn class_init(klass: &mut Self::Class) {
            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    #[glib::derived_properties]
    impl ObjectImpl for WelcomeDialog {}
    impl WidgetImpl for WelcomeDialog {}
    impl DialogImpl for WelcomeDialog {}
    impl WindowImpl for WelcomeDialog {}

    #[gtk::template_callbacks]
    impl WelcomeDialog {
        #[template_callback]
        fn next_clicked(&self) {
            //@TODO check the values

            self.stack.get().set_visible_child_name("authorization-screen");
        }

        #[template_callback]
        fn authorize_clicked(&self) {
            let email_address = self.email_address.borrow().clone().unwrap_or_default();
            let full_name = self.full_name.borrow().clone().unwrap_or_default();
            let account_name = self.account_name.borrow().clone().unwrap_or_default();

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

            self.stack.set_visible_child_name("check-browser");
        }
    }
}

glib::wrapper! {
    pub struct WelcomeDialog(ObjectSubclass<imp::WelcomeDialog>)
        @extends gtk::Widget, gtk::Dialog, gtk::Window;
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

        imp.spinner.start();
        imp.stack.set_visible_child_name("please-wait");
    }
}
