extern crate diesel;
extern crate futures;
extern crate gio;
extern crate glib;
extern crate gtk;
extern crate serde;

use diesel::prelude::*;

use crate::models;
use crate::schema;

use chrono::prelude::*;
use futures::prelude::*;
use gio::prelude::*;

use log::info;

use serde::Deserialize;

use crate::ui;

pub enum ApplicationMessage {
    SetupIdentity {
        email_address: String,
        full_name: String,
        account_name: String,
        identity_type: models::IdentityType,
        access_token: String,
        refresh_token: String,
        expires_at: DateTime<Utc>,
    },
    GoogleAuthorizationCodeReceived {
        email_address: String,
        full_name: String,
        account_name: String,
        authorization_code: String,
    },
    SetupDone {},
}

pub struct Application {
    main_window: ui::Window,
    welcome_dialog: ui::WelcomeDialog,
    application_message_sender: glib::Sender<ApplicationMessage>,
    context: glib::MainContext,
    database_connection_pool: diesel::r2d2::Pool<diesel::r2d2::ConnectionManager<diesel::sqlite::SqliteConnection>>,
}

use isahc::prelude::*;

#[derive(Serialize)]
struct GoogleTokensRequest {
    code: String,
    client_id: String,
    client_secret: String,
    redirect_uri: String,
    grant_type: String,
}

#[derive(Deserialize)]
struct GoogleTokensResponse {
    access_token: String,
    #[serde(deserialize_with = "duration_to_timestamp", rename = "expires_in")]
    expires_at: DateTime<Utc>,
    refresh_token: String,
}

fn duration_to_timestamp<'de, D>(deserializer: D) -> Result<DateTime<Utc>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let number_of_seconds = i64::deserialize(deserializer)?;
    let duration = chrono::Duration::seconds(number_of_seconds);
    Ok(Utc::now() + duration)
}

//@TODO move the constants to a nice configuration file
const CLIENT_SECRET: &str = "N_GoSZys__JPgKXrh_jIUuOh";
const CLIENT_ID: &str = "577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com";
const REDIRECT_URI: &str = "com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj:";

async fn request_tokens(authorization_code: String) -> Result<GoogleTokensResponse, isahc::Error> {
    let client = HttpClient::new()?;

    let request = GoogleTokensRequest {
        code: authorization_code,
        client_id: CLIENT_ID.to_string(),
        client_secret: CLIENT_SECRET.to_string(),
        redirect_uri: REDIRECT_URI.to_string(),
        grant_type: "authorization_code".to_string(),
    };

    let request = Request::post("https://www.googleapis.com/oauth2/v4/token")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())?;

    let mut response = client.send_async(request).await?;
    let tokens_response: GoogleTokensResponse = serde_json::from_str(&response.text_async().await?).unwrap(); //@TODO gracefully handle instead of unwrap

    Ok(tokens_response)
}

impl Application {
    pub fn run() {
        gtk::init().expect("Failed to initialize GTK Application");

        let gtk_application =
            gtk::Application::new(Some("com.github.matzipan.envoyer"), Default::default()).expect("Failed to initialize application");

        gtk_application.connect_startup(|gtk_application| {
            Application::on_startup(&gtk_application);
        });

        gtk_application.run(&[]);
    }

    fn on_startup(gtk_application: &gtk::Application) {
        gtk_application.connect_activate(|gtk_application| {
            let application = Application::new(gtk_application);

            application.on_activate();
        });
    }

    fn new(gtk_application: &gtk::Application) -> Application {
        let (application_message_sender, application_message_receiver) = glib::MainContext::channel(glib::PRIORITY_DEFAULT);
        let context = glib::MainContext::default();

        let database_connection_manager = diesel::r2d2::ConnectionManager::<diesel::sqlite::SqliteConnection>::new("db.sqlite");
        let database_connection_pool = diesel::r2d2::Pool::builder().build(database_connection_manager).unwrap();

        info!("Connected to the database");

        let application = Self {
            main_window: ui::Window::new(gtk_application),
            // Ideally this dialog would be created only if account setup is
            // needed, but to simplify reference passing right now, we're
            // always creating it.
            welcome_dialog: ui::WelcomeDialog::new(application_message_sender.clone()),
            application_message_sender: application_message_sender,
            context: context,
            database_connection_pool: database_connection_pool,
        };

        application.context.push_thread_default();

        let database_connection_pool = application.database_connection_pool.clone();
        let context_clone = application.context.clone();
        let welcome_dialog = application.welcome_dialog.clone(); //@TODO these should be rc not clones
        let main_window = application.main_window.clone(); //@TODO these should be rc not clones
        let application_message_sender = application.application_message_sender.clone();
        application_message_receiver.attach(None, move |msg| {
            match msg {
                ApplicationMessage::SetupIdentity {
                    email_address,
                    full_name,
                    account_name,
                    identity_type,
                    access_token,
                    refresh_token,
                    expires_at,
                } => {
                    info!("CreateIdentity for {}", email_address);

                    let new_identity = models::NewIdentity {
                        email_address: &email_address,
                        gmail_access_token: &access_token,
                        gmail_refresh_token: &refresh_token,
                        identity_type: identity_type,
                        expires_at: &expires_at.naive_utc(),
                        full_name: &full_name,
                        account_name: &account_name,
                    };

                    let connection = database_connection_pool.get().expect("Unable to acquire a database connection");
                    diesel::insert_into(schema::identities::table)
                        .values(&new_identity)
                        .execute(&connection)
                        .expect("Error saving new identity");

                    application_message_sender
                        .send(ApplicationMessage::SetupDone {})
                        .expect("Unable to send application message")
                }
                ApplicationMessage::GoogleAuthorizationCodeReceived {
                    email_address,
                    full_name,
                    account_name,
                    authorization_code,
                } => {
                    info!("GoogleAuthorizationCodeReceived for {}", email_address);

                    let application_message_sender = application_message_sender.clone();
                    context_clone.spawn(request_tokens(authorization_code).map(move |result| {
                        match result {
                            Err(error) => eprintln!("Got error: {}", error),
                            Ok(response_token) => application_message_sender
                                .send(ApplicationMessage::SetupIdentity {
                                    email_address: email_address,
                                    full_name: full_name,
                                    identity_type: models::IdentityType::Gmail,
                                    account_name: account_name,
                                    access_token: response_token.access_token,
                                    refresh_token: response_token.refresh_token,
                                    expires_at: response_token.expires_at,
                                })
                                .expect("Unable to send application message"),
                        }
                    }));
                }
                ApplicationMessage::SetupDone {} => {
                    welcome_dialog.hide();
                    main_window.show();
                }
            }
            // Returning false here would close the receiver and have senders
            // fail
            glib::Continue(true)
        });

        application.welcome_dialog.transient_for(&application.main_window);

        application
    }

    fn on_activate(self) {
        if self.is_setup_needed() {
            self.welcome_dialog.show();
        } else {
            self.main_window.show();
        }
    }

    fn is_setup_needed(&self) -> bool {
        let connection = self
            .database_connection_pool
            .get()
            .expect("Unable to acquire a database connection");

        let identities: i64 = schema::identities::table
            .select(diesel::dsl::count_star())
            .first(&connection)
            .expect("Unable to get the number of identities");

        identities == 0
    }
}
