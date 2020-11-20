#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate diesel;
extern crate gio;
extern crate gtk;

mod controllers;
mod google_oauth;
mod identity;
mod models;
mod schema;
mod ui;

use log::{Level, LevelFilter, Metadata, Record};

struct SimpleLogger;

impl log::Log for SimpleLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Info
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
        .map(|()| log::set_max_level(LevelFilter::Info))
        .expect("Unable to set up logger");
    // Intl.setlocale (LocaleCategory.ALL, Intl.get_language_names ()[0]);
    // Intl.textdomain (Config.GETTEXT_PACKAGE);

    // Environment.set_application_name (Constants.APP_NAME);
    // Environment.set_prgname (Constants.PROJECT_FQDN);

    controllers::Application::run();

    Ok(())
}
