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
    // Intl.setlocale (LocaleCategory.ALL, Intl.get_language_names ()[0]);
    // Intl.textdomain (Config.GETTEXT_PACKAGE);

    // Environment.set_application_name (Constants.APP_NAME);
    // Environment.set_prgname (Constants.PROJECT_FQDN);

    controllers::Application::run();

    Ok(())
}
