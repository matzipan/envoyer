extern crate gio;
extern crate glib;
extern crate gtk;
extern crate webkit2gtk;

use gtk::prelude::*;
use webkit2gtk::WebViewExt;

use log::info;

use glib::clone;

use url::Url;

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;
use crate::ui;
use crate::google_oauth;


struct FormData {
    pub email_address: Option<String>,
    pub full_name: Option<String>, 
    pub account_name: Option<String>
}

#[derive(Clone)]
pub struct WelcomeDialog {
    pub sender: glib::Sender<ApplicationMessage>,
    pub gtk_dialog: gtk::Dialog,
    pub submit_button: gtk::Button,
    pub stack: gtk::Stack,
    pub webview: webkit2gtk::WebView,
    pub email_address_entry: gtk::Entry,
    pub account_name_entry: gtk::Entry,
    pub full_name_entry: gtk::Entry,
    pub spinner: gtk::Spinner,
    form_data_rc: Rc<RefCell<FormData>>
}

impl WelcomeDialog {
    pub fn new(sender: glib::Sender<ApplicationMessage>) -> WelcomeDialog {
        let dialog = Self {
            sender: sender,
            gtk_dialog: gtk::Dialog::new(),
            submit_button: gtk::Button::with_label("Authorize"),
            stack: gtk::Stack::new(),
            webview: webkit2gtk::WebView::new(),
            email_address_entry: gtk::Entry::new(),
            account_name_entry: gtk::Entry::new(),
            full_name_entry: gtk::Entry::new(),
            spinner: gtk::Spinner::new(),
            form_data_rc: Rc::new(RefCell::new(FormData {
                email_address: None, full_name: None, account_name: None
            }))
        };

        dialog.build_ui();
        dialog.connect_signals();

        dialog
    }

    pub fn build_ui(&self) {
        //@TODO set icon

        self.gtk_dialog.get_style_context().add_class("welcome-dialog");
        self.gtk_dialog.set_size_request(1024, 1024);
        self.gtk_dialog.set_property_window_position(gtk::WindowPosition::Center);
        self.gtk_dialog.set_modal(true);
        self.gtk_dialog.set_resizable(false);
        self.gtk_dialog.set_border_width(5);

        self.webview.set_hexpand(true);
        self.webview.set_vexpand(true);

        //@TODO handle close button

        let welcome_label = gtk::Label::new(Some("Welcome!"));
        welcome_label.get_style_context().add_class("h1");
        welcome_label.set_halign(gtk::Align::Start);

        let description_label = gtk::Label::new(Some("Let's get you set up using the app. Enter your information below:"));
        description_label.set_margin_bottom(40);

        let email_address_label = gtk::Label::new(Some("E-mail address"));
        email_address_label.set_margin_end(30);

        self.email_address_entry.set_placeholder_text(Some("you@yourdomain.com"));

        let account_name_label = gtk::Label::new(Some("Account name"));
        account_name_label.set_margin_end(30);

        self.account_name_entry.set_placeholder_text(Some("Personal"));

        let full_name_label = gtk::Label::new(Some("Full name"));

        let full_name_info_image = gtk::Image::new();
        full_name_info_image.set_from_gicon(&gio::ThemedIcon::new("dialog-information-symbolic"), gtk::IconSize::Button);
        full_name_info_image.set_pixel_size(16);
        full_name_info_image.set_margin_end(30);
        full_name_info_image.set_tooltip_text(Some("Publicly visible. Used in the sender field of your e-mails."));

        self.full_name_entry.set_placeholder_text(Some("John Doe"));

        self.submit_button.set_halign(gtk::Align::End);
        self.submit_button.set_margin_top(40);

        let initial_information_grid = gtk::Grid::new();
        initial_information_grid.set_halign(gtk::Align::Center);
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
        welcome_screen.add(&welcome_label);
        welcome_screen.add(&description_label);
        welcome_screen.add(&initial_information_grid);
        welcome_screen.add(&self.submit_button);

        self.spinner.set_size_request(40, 40);
        self.spinner.set_halign(gtk::Align::Center);
        self.spinner.set_valign(gtk::Align::Center);

        let please_wait_label = gtk::Label::new(Some("Please wait"));
        please_wait_label.get_style_context().add_class("h1");
        please_wait_label.set_halign(gtk::Align::Start);

        let synchronizing_label = gtk::Label::new(Some("We are synchronizing with the server. It may take a while."));
        synchronizing_label.set_margin_bottom(40);

        let please_wait_grid = gtk::Grid::new();
        please_wait_grid.set_orientation(gtk::Orientation::Vertical);
        please_wait_grid.set_halign(gtk::Align::Center);
        please_wait_grid.set_valign(gtk::Align::Center);
        please_wait_grid.add(&please_wait_label);
        please_wait_grid.add(&synchronizing_label);
        please_wait_grid.add(&self.spinner);

        self.stack.add_named(&welcome_screen, "welcome-screen");
        self.stack.add_named(&self.webview, "webview");
        self.stack.add_named(&please_wait_grid, "please-wait");

        self.gtk_dialog.get_content_area().add(&self.stack);
    }

    pub fn connect_signals(&self) {
        let stack = self.stack.clone();
        let email_address_entry = self.email_address_entry.clone();
        let account_name_entry = self.account_name_entry.clone();
        let full_name_entry = self.full_name_entry.clone();
        let webview = self.webview.clone();
        let form_data_rc = self.form_data_rc.clone();

        self.submit_button
            .connect_clicked(clone!(@weak stack, @weak email_address_entry, @weak account_name_entry, @weak full_name_entry, @weak webview => move |_| {
                let email_address = email_address_entry.get_text().to_string();
                let full_name = full_name_entry.get_text().to_string();
                let account_name = account_name_entry.get_text().to_string();

                //@TODO check the values

                let email_address_clone = email_address.clone();

                let mut form_data = form_data_rc.borrow_mut();

                form_data.email_address = Some(email_address);
                form_data.full_name = Some(full_name);
                form_data.account_name = Some(account_name);

                stack.set_visible_child_name("webview");

                webview.load_uri(&format!(
                    "https://accounts.google.com/o/oauth2/v2/auth?scope={scope}&login_hint={email_address}&response_type=code&\
                    redirect_uri={redirect_uri}&client_id={client_id}",
                    scope = google_oauth::OAUTH_SCOPE,
                    email_address = email_address_clone,
                    redirect_uri = google_oauth::REDIRECT_URI,
                    client_id = google_oauth::CLIENT_ID
                ));
            }));

        let spinner = self.spinner.clone();
        let sender = self.sender.clone();
        let form_data_rc = self.form_data_rc.clone();
        self.webview.connect_load_changed(clone!(@weak spinner, @strong sender => move |webview, event| {
                if event == webkit2gtk::LoadEvent::Started {
                    let webview_uri = String::from(webview.get_uri().expect("Unable to fetch URI from WebView"));

                    if webview_uri.starts_with(google_oauth::REDIRECT_URI) {
                        stack.set_visible_child_name("please-wait");
                        spinner.start();

                        //@TODO gracefully handle instead of unwrap and expect
                        let request_url = Url::parse(&webview_uri).unwrap();
                        let authorization_code = request_url.query_pairs().into_owned().find(|x| x.0 == "code").expect("Unable to fetch authorization code from Google authenticaiton");

                        info!("Received authorization code from Google authentication");

                        let form_data = form_data_rc.borrow();
                        
                        sender.send(ApplicationMessage::GoogleAuthorizationCodeReceived {
                            // The fields cannot be none since it is a
                            // precondition that they will be set before a load
                            // is triggered
                            email_address: (&form_data.email_address.as_ref().unwrap()).to_string(),
                            full_name: (&form_data.full_name.as_ref().unwrap()).to_string(),
                            account_name: (&form_data.account_name.as_ref().unwrap()).to_string(),
                            authorization_code: authorization_code.1
                        }).expect("Unable to send application message");
                    }
                }
            }));
    }

    pub fn show(&self) {
        self.gtk_dialog.show_all();
        self.gtk_dialog.present();
    }

    pub fn hide(&self) {
        self.gtk_dialog.hide();
    }

    pub fn transient_for(&self, main_window: &ui::Window) {
        self.gtk_dialog.set_transient_for(Some(&main_window.gtk_window));
    }
}
