extern crate gdk;
extern crate gio;
extern crate gtk;

use gtk::prelude::*;

#[derive(Clone)]
pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
}

impl Window {
    pub fn new(application: &gtk::Application) -> Window {
        //@TODO set icon
        let gtk_window = gtk::ApplicationWindow::new(application);
        let header = gtk::HeaderBar::new();
        header.set_title(Some("Envoyer"));
        header.set_show_close_button(true);
        gtk_window.set_titlebar(Some(&header));
        gtk_window.set_title("Envoyer");
        gtk_window.set_wmclass("envoyer", "Envoyer");
        gtk_window.resize(1600, 900);

        gtk::Window::set_default_icon_name("iconname");
        let my_str = include_str!("stylesheet.css");
        let provider = gtk::CssProvider::new();
        provider.load_from_data(my_str.as_bytes()).expect("Failed to load CSS");
        gtk::StyleContext::add_provider_for_screen(
            &gdk::Screen::get_default().expect("Error initializing gtk css provider."),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        Self { gtk_window }
    }

    pub fn show(&self) {
        self.gtk_window.show_all();
        self.gtk_window.present();
    }
}
