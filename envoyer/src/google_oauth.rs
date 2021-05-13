use gtk::gio;

use chrono::prelude::*;
use isahc::prelude::*;

use log::{debug, info};

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

pub async fn request_tokens(authorization_code: String, redirect_uri: String) -> Result<GoogleTokensResponse, isahc::Error> {
    let client = HttpClient::new()?;

    let request = GoogleTokensRequest {
        code: &authorization_code,
        client_id: &CLIENT_ID.to_string(),
        client_secret: &CLIENT_SECRET.to_string(),
        redirect_uri: &redirect_uri,
        grant_type: &"authorization_code".to_string(),
    };

    let request = Request::post(TOKEN_ENDPOINT)
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())?;

    let mut response = client.send_async(request).await?;

    //@TODO gracefully handle instead of unwrap
    let response_text = response.text_async().await.unwrap();
    let tokens_response: GoogleTokensResponse = serde_json::from_str(&response_text).unwrap();

    Ok(tokens_response)
}

pub async fn authenticate(email_address: String) -> Result<GoogleTokensResponse, String> {
    let (authorization_code_sender, mut authorization_code_receiver) = futures::channel::mpsc::channel(1);
    let (mut address_sender, mut address_receiver) = futures::channel::mpsc::channel(1);
    let (instance_sender, instance_receiver) = std::sync::mpsc::channel();

    // Actix is a bit more prententious about the way it wants to run, therefore we
    // spin up its own thread, where we give it control. We then call stop on the
    // server which should make it gracefully shut down and free up the thread.
    std::thread::spawn(move || {
        let mut system = actix_web::rt::System::new("AuthorizationCodeReceiverThread");
        let receiver = services::AuthorizationCodeReceiver::new(authorization_code_sender).expect("bla");

        instance_sender.send(receiver.clone());

        address_sender
            .try_send(receiver.get_address())
            .expect("Unable to send address over channel");

        system.block_on(receiver.run());
        debug!("Authorization code receiver stopped");
    });

    let token_receiver_address = address_receiver.next().await.unwrap(); //@TODO

    open_browser(&email_address, &token_receiver_address)
        .await
        .map_err(|e| format!("Unable to open URL in browser: {}", e))?;

    let authorization_code = authorization_code_receiver.next().await.expect("BLA");

    debug!("Got authorization code");
    //@TODO handle the case where error is returned because the sender is closed

    // Shut down the HTTP server
    let receiver = instance_receiver.recv().expect("Unable to receive server instance for shutdown");

    receiver.stop().await;

    request_tokens(authorization_code, token_receiver_address)
        .await
        .map_err(|e| e.to_string())
}

pub async fn open_browser(email_address: &String, token_receiver_address: &String) -> Result<(), String> {
    gio::AppInfo::launch_default_for_uri_async_future(
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
