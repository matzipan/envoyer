#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate diesel;

extern crate diesel_migrations;

mod backends;
mod bindings;
mod controllers;
mod google_oauth;
mod litehtml_callbacks;
mod models;
mod schema;
mod services;
mod ui;

#[rustfmt::skip]
mod config;

use controllers::ApplicationProfile;
use gettextrs::{gettext, LocaleCategory};
use gtk::{gio, glib};


use adw::prelude::*;

use self::config::{GETTEXT_PACKAGE, LOCALEDIR, PROFILE, RESOURCES_FILE};

use log::{debug, Level, LevelFilter, Metadata, Record};

struct SimpleLogger;

impl log::Log for SimpleLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Debug
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            println!("{} - {}", record.level(), record.args());
        }
    }

    fn flush(&self) {}
}

static LOGGER: SimpleLogger = SimpleLogger;

fn main() -> glib::ExitCode {
    log::set_logger(&LOGGER)
        .map(|()| log::set_max_level(LevelFilter::Debug))
        .expect("Unable to set up logger");

    // Prepare i18n
    gettextrs::setlocale(LocaleCategory::LcAll, "");
    gettextrs::bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR).expect("Unable to bind the text domain");
    gettextrs::textdomain(GETTEXT_PACKAGE).expect("Unable to switch to the text domain");

    glib::set_application_name(&gettext("Envoyer"));

    let res = gio::Resource::load(RESOURCES_FILE).expect("Could not load gresource file");
    gio::resources_register(&res);

    gtk::init().expect("Failed to initialize GTK Application");
    adw::init().unwrap();

    let app = controllers::Application::default();

    if PROFILE == ApplicationProfile::Devel {
        debug!("Detected development build");

        app.add_main_option(
            "with-test-server",
            b't'.into(),
            glib::OptionFlags::NONE,
            glib::OptionArg::None,
            &gettext("Sets up connection for test server"),
            None,
        );
    }

    app.run()
}
