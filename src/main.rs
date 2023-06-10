#![feature(hash_drain_filter)]

#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate diesel;

#[macro_use]
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

use gettextrs::{gettext, LocaleCategory};
use gtk::{gio, glib};

use self::config::{GETTEXT_PACKAGE, LOCALEDIR, RESOURCES_FILE};

use log::{Level, LevelFilter, Metadata, Record};

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

fn main() -> std::io::Result<()> {
    log::set_logger(&LOGGER)
        .map(|()| log::set_max_level(LevelFilter::Debug))
        .expect("Unable to set up logger");

    // Prepare i18n
    gettextrs::setlocale(LocaleCategory::LcAll, "");
    gettextrs::bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR).expect("Unable to bind the text domain");
    gettextrs::textdomain(GETTEXT_PACKAGE).expect("Unable to switch to the text domain");

    glib::set_application_name(&gettext("Envoyer"));

    // Not really using resources now and can't really bothered with it
    // let res = gio::Resource::load(RESOURCES_FILE).expect("Could not load
    // gresource file"); gio::resources_register(&res);

    controllers::Application::run();

    Ok(())
}
