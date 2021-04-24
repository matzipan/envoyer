use gtk::glib;

use log::{debug, error, info};

use tide::listener::ToListener;
use tide::prelude::*;

use rand::{thread_rng, Rng};

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;

#[derive(Clone)]
struct TokenReceiverServerState {
    application_message_sender: glib::Sender<ApplicationMessage>,
}

impl TokenReceiverServerState {
    fn new(application_message_sender: glib::Sender<ApplicationMessage>) -> Self {
        Self {
            application_message_sender,
        }
    }
}

#[derive(Debug, Deserialize)]
struct GoogleAuthorizationResponse {
    code: String,
}

pub struct TokenReceiver {
    port_number: u32,
    binding: std::net::TcpListener,
}

impl TokenReceiver {
    const PORT_RANGE: std::ops::Range<u32> = 49152..65535;
    const IP_ADDRESS: &'static str = "127.0.0.1";

    pub fn new() -> Result<TokenReceiver, std::io::Error> {
        let (port_number, binding) = Self::get_binding()?;

        Ok(TokenReceiver {
            port_number,
            binding: binding,
        })
    }

    fn get_binding() -> Result<(u32, std::net::TcpListener), std::io::Error> {
        let mut port_number = Self::PORT_RANGE.start;

        loop {
            debug!("Attempting to bind to port {}", port_number);
            match std::net::TcpListener::bind(format!("{}:{}", Self::IP_ADDRESS, port_number)) {
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
                    return Ok((port_number, binding));
                }
            }
        }
    }

    pub async fn start(self, application_message_sender: glib::Sender<ApplicationMessage>) -> std::io::Result<()> {
        let mut server_instance = tide::with_state(TokenReceiverServerState::new(application_message_sender));
        server_instance.at("/").get(Self::get_token);

        let mut listener = self.binding.to_listener()?;
        listener.bind(server_instance).await?;
        listener.accept().await?;

        Ok(())
    }

    pub fn get_address(&self) -> String {
        format!("http://{}:{}/", Self::IP_ADDRESS, self.port_number)
    }

    async fn get_token(mut req: tide::Request<TokenReceiverServerState>) -> tide::Result {
        let state = req.state();

        let authorization_response: GoogleAuthorizationResponse = req.query()?;

        state
            .application_message_sender
            .send(ApplicationMessage::GoogleAuthorizationCodeReceived {
                account_name: "Gmail".to_string(), //@TODO
                email_address: "matzipan@gmail.com".to_string(),
                full_name: "Andrei Zisu".to_string(),
                authorization_code: authorization_response.code,
            });

        Ok(format!("Request received. You can close this window").into())
    }
}
