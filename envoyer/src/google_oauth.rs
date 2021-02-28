use chrono::prelude::*;
use isahc::prelude::*;

use log::info;

use serde::Deserialize;

//@TODO move the constants to a nice configuration file
pub const CLIENT_SECRET: &str = "N_GoSZys__JPgKXrh_jIUuOh";
pub const CLIENT_ID: &str = "577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com";
pub const REDIRECT_URI: &str = "com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj:";
pub const OAUTH_SCOPE: &str = "https://mail.google.com/";

#[derive(Serialize)]
struct GoogleAccessTokenRefreshRequest<'a> {
    refresh_token: &'a String,
    client_id: &'a String,
    client_secret: &'a String,
    grant_type: &'a String,
}

#[derive(Deserialize)]
pub struct GoogleAccessTokenRefreshResponse {
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

pub async fn refresh_access_token(refresh_token: &String) -> Result<GoogleAccessTokenRefreshResponse, ()> {
    info!("Refreshing access token");

    let client = HttpClient::new().unwrap();

    let request = GoogleAccessTokenRefreshRequest {
        refresh_token: &refresh_token,
        client_id: &CLIENT_ID.to_string(),
        client_secret: &CLIENT_SECRET.to_string(),
        grant_type: &"refresh_token".to_string(),
    };

    let request = Request::post("https://www.googleapis.com/oauth2/v4/token")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())
        .unwrap();

    let mut response = client.send_async(request).await.unwrap();

    //@TODO gracefully handle instead of unwrap
    let response_text = response.text_async().await.unwrap();
    let tokens_response: GoogleAccessTokenRefreshResponse = serde_json::from_str(&response_text).unwrap();

    info!("Access token refreshed");

    Ok(tokens_response)
}

#[derive(Serialize)]
struct GoogleAuthorizationCodeRequest<'a> {
    code: &'a String,
    client_id: &'a String,
    client_secret: &'a String,
    redirect_uri: &'a String,
    grant_type: &'a String,
}

#[derive(Deserialize)]
pub struct GoogleAuthorizationCodeResponse {
    pub access_token: String,
    #[serde(deserialize_with = "duration_to_timestamp", rename = "expires_in")]
    pub expires_at: DateTime<Utc>,
    pub refresh_token: String,
}

pub async fn request_tokens(authorization_code: String) -> Result<GoogleAuthorizationCodeResponse, isahc::Error> {
    let client = HttpClient::new()?;

    let request = GoogleAuthorizationCodeRequest {
        code: &authorization_code,
        client_id: &CLIENT_ID.to_string(),
        client_secret: &CLIENT_SECRET.to_string(),
        redirect_uri: &REDIRECT_URI.to_string(),
        grant_type: &"authorization_code".to_string(),
    };

    let request = Request::post("https://www.googleapis.com/oauth2/v4/token")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body(serde_qs::to_string(&request).unwrap())?;

    let mut response = client.send_async(request).await?;

    //@TODO gracefully handle instead of unwrap
    let response_text = response.text_async().await.unwrap();
    let tokens_response: GoogleAuthorizationCodeResponse = serde_json::from_str(&response_text).unwrap();

    Ok(tokens_response)
}
