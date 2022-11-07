use gtk::gio;

use chrono::prelude::*;
use isahc::prelude::*;

use log::{debug, error, info};

use serde::Deserialize;

use futures::prelude::*;

use crate::services;

//@TODO move the constants to a nice configuration file
pub const CLIENT_SECRET: &str = "N_GoSZys__JPgKXrh_jIUuOh";
pub const CLIENT_ID: &str = "577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com";
pub const OAUTH_SCOPE: &str = "https://mail.google.com/";
pub const TOKEN_ENDPOINT: &str = "https://www.googleapis.com/oauth2/v4/token";

#[derive(Serialize)]
struct GoogleAccessTokenRefreshRequest<'a> {
    refresh_token: &'a String,
    client_id: &'a String,
    client_secret: &'a String,
    grant_type: &'a String,
}

#[derive(Deserialize)]
pub struct GoogleTokenRefreshResponse {
    pub access_token: String,
    #[serde(deserialize_with = "duration_to_timestamp", rename = "expires_in")]
    pub expires_at: DateTime<Utc>,
    pub scope: String,
    pub token_type: String,
}

#[derive(Clone, Debug)]
pub struct AuthenticationResult {
    pub authorization_code: String,
    pub redirect_uri: String,
}

fn duration_to_timestamp<'de, D>(deserializer: D) -> Result<DateTime<Utc>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let number_of_seconds = i64::deserialize(deserializer)?;
    let duration = chrono::Duration::seconds(number_of_seconds);
    Ok(Utc::now() + duration)
}

pub async fn refresh_access_token(refresh_token: &String) -> Result<GoogleTokenRefreshResponse, ()> {
    info!("Refreshing access token");

    let client = HttpClient::new().unwrap();

    let request = GoogleAccessTokenRefreshRequest {
        refresh_token: &refresh_token,
        client_id: &CLIENT_ID.to_string(),
        client_secret: &CLIENT_SECRET.to_string(),
        grant_type: &"refresh_token".to_string(),
    };

    let request = Request::post(TOKEN_ENDPOINT)
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())
        .unwrap();

    let mut response = client.send_async(request).await.unwrap();

    //@TODO gracefully handle instead of unwrap
    let response_text = response.text_async().await.unwrap();
    let tokens_response: GoogleTokenRefreshResponse = serde_json::from_str(&response_text).unwrap();

    info!("Access token refreshed");

    Ok(tokens_response)
}

#[derive(Serialize)]
struct GoogleTokensRequest<'a> {
    code: &'a String,
    client_id: &'a String,
    client_secret: &'a String,
    redirect_uri: &'a String,
    grant_type: &'a String,
}

#[derive(Deserialize)]
pub struct GoogleTokensResponse {
    pub access_token: String,
    #[serde(deserialize_with = "duration_to_timestamp", rename = "expires_in")]
    pub expires_at: DateTime<Utc>,
    pub refresh_token: String,
}

pub async fn request_tokens(authentication_result: AuthenticationResult) -> Result<GoogleTokensResponse, String> {
    let client = HttpClient::new().map_err(|e| e.to_string())?;

    let request = GoogleTokensRequest {
        code: &authentication_result.authorization_code,
        client_id: &CLIENT_ID.to_string(),
        client_secret: &CLIENT_SECRET.to_string(),
        redirect_uri: &authentication_result.redirect_uri,
        grant_type: &"authorization_code".to_string(),
    };

    let request = Request::post(TOKEN_ENDPOINT)
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())
        .map_err(|e| e.to_string())?;

    let mut response = client.send_async(request).await.map_err(|e| e.to_string())?;

    let response_text = response.text_async().await.map_err(|e| e.to_string())?;
    let tokens_response: GoogleTokensResponse = serde_json::from_str(&response_text).map_err(|e| e.to_string())?;

    Ok(tokens_response)
}

pub async fn authenticate(email_address: String) -> Result<AuthenticationResult, String> {
    let (authorization_code_sender, mut authorization_code_receiver) = futures::channel::mpsc::channel(1);
    let (mut address_sender, mut address_receiver) = futures::channel::mpsc::channel(1);
    let (instance_sender, instance_receiver) = std::sync::mpsc::channel();

    // Actix is a bit more prententious about the way it wants to run, therefore we
    // spin up its own thread, where we give it control. We then call stop on the
    // server which should make it gracefully shut down and free up the thread.
    std::thread::spawn(move || {
        let mut system = actix_web::rt::System::new("AuthorizationCodeReceiverThread");

        services::AuthorizationCodeReceiver::new(authorization_code_sender)
            .map_err(|e| e.to_string())
            .and_then(move |receiver| {
                instance_sender.send(receiver.clone()).map_err(|e| e.to_string())?;

                address_sender.try_send(receiver.get_address()).map_err(|e| e.to_string())?;

                system.block_on(receiver.run()).map_err(|e| e.to_string())?;

                debug!("Authorization code receiver stopped");

                Ok(())
            })
            .map_err(|err| {
                //@TODO propagate to future thread
                error!("Unable to authenticate: {}", err);
            });
    });

    let token_receiver_address = address_receiver.next().await.ok_or("Unable to get receiver address")?;

    open_browser(&email_address, &token_receiver_address)
        .await
        .map_err(|e| format!("Unable to open URL in browser: {}", e))?;

    let authorization_code = authorization_code_receiver.next().await.ok_or("Unable to get authorization code")?;

    debug!("Got authorization code");

    // Shut down the HTTP server. The lifetime of the channel sender is tied to the
    // server runtime thread, so if there's an error which causes the deallocation
    // of the sender, it's not possible that the server will be left running.
    let receiver = instance_receiver.recv().map_err(|e| e.to_string())?;

    receiver.stop().await;

    Ok(AuthenticationResult {
        authorization_code,
        redirect_uri: token_receiver_address,
    })
}

pub async fn open_browser(email_address: &String, token_receiver_address: &String) -> Result<(), String> {
    gio::AppInfo::launch_default_for_uri_future(
        &format!(
            "https://accounts.google.com/o/oauth2/v2/auth?scope={scope}&login_hint={email_address}&response_type=code&redirect_uri={redirect_uri}&client_id={client_id}",
            scope = OAUTH_SCOPE,
            email_address = email_address,
            redirect_uri = token_receiver_address,
            client_id = CLIENT_ID
        ),
        None::<&gio::AppLaunchContext>,
    )
    .await
    .map_err(|e| e.to_string())
}
