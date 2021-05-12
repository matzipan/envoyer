use gtk::glib;

use log::{debug, error, info};

use rand::{thread_rng, Rng};

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::mpsc;

use crate::controllers::ApplicationMessage;

#[derive(Debug, Deserialize)]
struct GoogleAuthorizationResponse {
    code: String,
}

pub struct AuthorizationCodeReceiver {
    port_number: u32,
    server: actix_web::dev::Server,
}

pub const SUCCESS_HTML_RESPONSE: &str = "<!DOCTYPE html>
    <html lang=\"en\">
    <head><meta charset=\"utf-8\" />
    <style>
    body { font-family: sans-serif; }
    </style>
    <title>Authorization successful - Envoyer</title>
    </head>
    <body>
    <h1>Authorization successful</h1>
    <p>The authorization code has been successfully received. You can now close this window and switch to Envoyer.</p>
    </body>
    </html>";

#[actix_web::get("/")]
async fn get_token(
    actix_web::web::Query(authorization_response): actix_web::web::Query<GoogleAuthorizationResponse>,
    data: actix_web::web::Data<futures::channel::mpsc::Sender<String>>,
) -> impl actix_web::Responder {
    data.get_ref().clone().try_send(authorization_response.code).expect("BLA"); //@TODO

    SUCCESS_HTML_RESPONSE
}

impl AuthorizationCodeReceiver {
    const PORT_RANGE: std::ops::Range<u32> = 49152..65535;
    const IP_ADDRESS: &'static str = "127.0.0.1";

    pub fn new(tx: futures::channel::mpsc::Sender<String>) -> Result<AuthorizationCodeReceiver, std::io::Error> {
        let (port_number, server) = Self::get_server(tx)?;

        Ok(AuthorizationCodeReceiver { port_number, server })
    }

    fn get_server(tx: futures::channel::mpsc::Sender<String>) -> Result<(u32, actix_web::dev::Server), std::io::Error> {
        let mut port_number = Self::PORT_RANGE.start;

        loop {
            debug!("Attempting to bind to port {}", port_number);
            let tx_clone = tx.clone();

            match actix_web::HttpServer::new(move || {
                let tx_clone = tx_clone.clone();

                actix_web::App::new()
                    .app_data(actix_web::web::Data::new(tx_clone))
                    .service(get_token)
            })
            .workers(1)
            .bind(format!("{}:{}", Self::IP_ADDRESS, port_number))
            {
                Err(e) => match e.kind() {
                    std::io::ErrorKind::AddrInUse => {
                        debug!("Port {} is taken. Trying a new one", port_number);
                        let mut rng = rand::thread_rng();
                        port_number = rng.gen_range(Self::PORT_RANGE);
                    }
                    _ => {
                        error!("Could not bind to interface");
                        return Err(e);
                    }
                },
                Ok(binding) => {
                    info!("Bound the token receiver to port {}", port_number);
                    return Ok((port_number, binding.run()));
                }
            }
        }
    }

    pub async fn run(self) -> std::io::Result<()> {
        self.server.await;

        Ok(())
    }

    pub fn get_address(&self) -> String {
        format!("http://{}:{}/", Self::IP_ADDRESS, self.port_number)
    }
}
