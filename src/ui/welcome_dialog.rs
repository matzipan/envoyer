use gtk;

use gtk::gio;
use gtk::glib;
use gtk::glib::clone;
use gtk::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;
use crate::ui;

struct FormData {
    pub email_address: Option<String>,
    pub full_name: Option<String>,
    pub account_name: Option<String>,
}

#[derive(Clone)]
pub struct WelcomeDialog {
    pub sender: glib::Sender<ApplicationMessage>,
    pub gtk_dialog: gtk::Dialog,
    pub authorize_button: gtk::Button,
    pub submit_button: gtk::Button,
    pub stack: gtk::Stack,
    pub email_address_entry: gtk::Entry,
    pub account_name_entry: gtk::Entry,
    pub full_name_entry: gtk::Entry,
    pub spinner: gtk::Spinner,
    form_data_rc: Rc<RefCell<FormData>>,
}

impl WelcomeDialog {
    pub fn new(sender: glib::Sender<ApplicationMessage>) -> WelcomeDialog {
        let dialog = Self {
            sender: sender,
            // Workaround for the desktop manager seemingly taking over headerbars?
            gtk_dialog: gtk::Dialog::with_buttons(
                Some(""),
                None::<&gtk::Window>,
                gtk::DialogFlags::USE_HEADER_BAR | gtk::DialogFlags::MODAL,
                &[],
            ),
            authorize_button: gtk::Button::with_label("Authorize"),
            submit_button: gtk::Button::with_label("Next"),
            stack: gtk::Stack::new(),
            email_address_entry: gtk::Entry::new(),
            account_name_entry: gtk::Entry::new(),
            full_name_entry: gtk::Entry::new(),
            spinner: gtk::Spinner::new(),
            form_data_rc: Rc::new(RefCell::new(FormData {
                email_address: None,
                full_name: None,
                account_name: None,
            })),
        };

        dialog.build_ui();
        dialog.connect_signals();

        dialog
    }

    pub fn build_ui(&self) {
        //@TODO set icon

        self.gtk_dialog.style_context().add_class("welcome_dialog");
        self.gtk_dialog.set_size_request(1024, 1024);
        self.gtk_dialog.set_modal(true);

        //@TODO handle close button

        let welcome_label = gtk::Label::new(Some("Welcome!"));
        welcome_label.style_context().add_class("h1");
        welcome_label.set_halign(gtk::Align::Start);

        let description_label = gtk::Label::new(Some("Let's get you set up using the app. Enter your information below:"));

        let email_address_label = gtk::Label::new(Some("E-mail address"));
        email_address_label.set_halign(gtk::Align::Start);
        email_address_label.style_context().add_class("form-label");

        self.email_address_entry.set_placeholder_text(Some("you@yourdomain.com"));
        self.email_address_entry.style_context().add_class("form_entry");

        let account_name_label = gtk::Label::new(Some("Account name"));
        account_name_label.set_halign(gtk::Align::Start);
        account_name_label.style_context().add_class("form-label");

        self.account_name_entry.set_placeholder_text(Some("Personal"));
        self.account_name_entry.style_context().add_class("form_entry");

        let full_name_label = gtk::Label::new(Some("Full name"));
        full_name_label.set_halign(gtk::Align::Start);
        full_name_label.style_context().add_class("form-label");

        let full_name_info_image = gtk::Image::new();
        full_name_info_image.set_from_gicon(&gio::ThemedIcon::new("dialog-information-symbolic"));
        full_name_info_image.set_pixel_size(15);
        full_name_info_image.set_tooltip_text(Some("Publicly visible. Used in the sender field of your e-mails."));

        self.full_name_entry.set_placeholder_text(Some("John Doe"));
        self.full_name_entry.style_context().add_class("form_entry");

        self.submit_button.set_halign(gtk::Align::End);
        self.submit_button.style_context().add_class("button");

        let initial_information_grid = gtk::Grid::new();
        initial_information_grid.style_context().add_class("initial_information_grid");
        initial_information_grid.set_halign(gtk::Align::Center);
        initial_information_grid.set_hexpand(true);
        initial_information_grid.set_vexpand(true);
        initial_information_grid.set_row_spacing(5);
        initial_information_grid.attach(&email_address_label, 0, 0, 2, 1);
        initial_information_grid.attach(&self.email_address_entry, 2, 0, 1, 1);
        initial_information_grid.attach(&account_name_label, 0, 1, 2, 1);
        initial_information_grid.attach(&self.account_name_entry, 2, 1, 1, 1);
        initial_information_grid.attach(&full_name_label, 0, 2, 1, 1);
        initial_information_grid.attach(&full_name_info_image, 1, 2, 1, 1);
        initial_information_grid.attach(&self.full_name_entry, 2, 2, 1, 1);

        let welcome_screen = gtk::Grid::new();
        welcome_screen.set_halign(gtk::Align::Center);
        welcome_screen.set_valign(gtk::Align::Center);
        welcome_screen.set_orientation(gtk::Orientation::Vertical);
        welcome_screen.attach(&welcome_label, 0, 0, 1, 1);
        welcome_screen.attach(&description_label, 0, 1, 1, 1);
        welcome_screen.attach(&initial_information_grid, 0, 2, 1, 1);
        welcome_screen.attach(&self.submit_button, 0, 3, 1, 1);

        let authorization_label = gtk::Label::new(Some("Authorization"));
        authorization_label.set_halign(gtk::Align::Start);
        authorization_label.style_context().add_class("h1");
        let description_label = gtk::Label::new(Some(
            "Clicking the button will open a browser window requesting you to authorize Envoyer to read your e-mails.",
        ));
        self.authorize_button.set_halign(gtk::Align::End);
        self.authorize_button.style_context().add_class("button");

        let authorization_screen = gtk::Grid::new();
        authorization_screen.set_halign(gtk::Align::Center);
        authorization_screen.set_valign(gtk::Align::Center);
        authorization_screen.set_orientation(gtk::Orientation::Vertical);
        authorization_screen.attach(&authorization_label, 0, 0, 1, 1);
        authorization_screen.attach(&description_label, 0, 1, 1, 1);
        authorization_screen.attach(&self.authorize_button, 0, 2, 1, 1);

        let check_browser_label = gtk::Label::new(Some("Check your Internet browser"));
        check_browser_label.style_context().add_class("h1");
        check_browser_label.set_halign(gtk::Align::Start);

        let browser_window_label = gtk::Label::new(Some(
            "A browser window was opened to authenticate with your e-mail provider. Please continue there.",
        ));

        let check_browser_grid = gtk::Grid::new();
        check_browser_grid.set_orientation(gtk::Orientation::Vertical);
        check_browser_grid.set_halign(gtk::Align::Center);
        check_browser_grid.set_valign(gtk::Align::Center);
        check_browser_grid.attach(&check_browser_label, 0, 0, 1, 1);
        check_browser_grid.attach(&browser_window_label, 0, 1, 1, 1);

        self.spinner.set_size_request(40, 40);
        self.spinner.set_halign(gtk::Align::Center);
        self.spinner.set_valign(gtk::Align::Center);

        let please_wait_label = gtk::Label::new(Some("Please wait"));
        please_wait_label.style_context().add_class("h1");
        please_wait_label.set_halign(gtk::Align::Start);

        let synchronizing_label = gtk::Label::new(Some("Synchronizing with the server. It may take a while."));
        synchronizing_label.set_margin_bottom(40);

        let please_wait_grid = gtk::Grid::new();
        please_wait_grid.set_orientation(gtk::Orientation::Vertical);
        please_wait_grid.set_halign(gtk::Align::Center);
        please_wait_grid.set_valign(gtk::Align::Center);
        please_wait_grid.attach(&please_wait_label, 0, 0, 1, 1);
        please_wait_grid.attach(&synchronizing_label, 0, 1, 1, 1);
        please_wait_grid.attach(&self.spinner, 0, 2, 1, 1);

        self.stack.add_named(&welcome_screen, Some("welcome-screen"));
        self.stack.add_named(&authorization_screen, Some("authorization-screen"));
        self.stack.add_named(&check_browser_grid, Some("check-browser"));
        self.stack.add_named(&please_wait_grid, Some("please-wait"));

        self.gtk_dialog.content_area().append(&self.stack);
    }

    pub fn connect_signals(&self) {
        let stack = self.stack.clone();
        let email_address_entry = self.email_address_entry.clone();
        let account_name_entry = self.account_name_entry.clone();
        let full_name_entry = self.full_name_entry.clone();
        let form_data_rc = self.form_data_rc.clone();

        self.submit_button
            .connect_clicked(clone!(@weak stack, @weak email_address_entry, @weak
            account_name_entry, @weak full_name_entry => move |_| {
                let email_address = email_address_entry.text().to_string();
                let full_name = full_name_entry.text().to_string();
                let account_name = account_name_entry.text().to_string();

                //@TODO check the values

                let mut form_data = form_data_rc.borrow_mut();

                form_data.email_address = Some(email_address);
                form_data.full_name = Some(full_name);
                form_data.account_name = Some(account_name);

                stack.set_visible_child_name("authorization-screen");
            }));

        let form_data_rc = self.form_data_rc.clone();
        let sender_clone = self.sender.clone();

        self.authorize_button.connect_clicked(move |_| {
            let form_data = form_data_rc.borrow();
            sender_clone
                .send(ApplicationMessage::OpenGoogleAuthentication {
                    email_address: form_data.email_address.as_ref().unwrap().clone(),
                    full_name: form_data.full_name.as_ref().unwrap().clone(),
                    account_name: form_data.account_name.as_ref().unwrap().clone(),
                })
                .expect("Unable to send application message");

            stack.set_visible_child_name("check-browser");
        });
    }

    pub fn show(&self) {
        self.gtk_dialog.show();
        self.gtk_dialog.present_with_time((glib::monotonic_time() / 1000) as u32);
    }

    pub fn hide(&self) {
        self.gtk_dialog.hide();
    }

    pub fn transient_for(&self, main_window: &ui::Window) {
        self.gtk_dialog.set_transient_for(Some(&main_window.gtk_window));
    }

    pub fn show_please_wait(&self) {
        self.spinner.start();
        self.stack.set_visible_child_name("please-wait");
    }
}
