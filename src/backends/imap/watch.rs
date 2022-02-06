// Copyright 2019 Manos Pitsidianakis - meli
// Copyright 2021 Andrei Zisu - envoyer

use super::*;

use melib::backends::imap::{ImapConnection, ImapLineSplit, ImapServerConf, RequiredResponses};
use melib::backends::BackendEventConsumer;

use melib::connections::timeout;

use melib::MeliError;

use log::debug;

use std::sync::Arc;
use std::time::Duration;

#[derive(Debug)]
pub enum WatchReturnReason {
    Timeout,
    //@TODO this should be likely less IMAP dependent (no EXISTS or EXPUNGE responses), but it'll do for now
    Updates(Vec<UntaggedResponse>),
}

pub struct WatchJob {
    pub server_conf: ImapServerConf,
    pub reconnect_timeout_duration: Option<Duration>,
    pub idle_timeout_duration: Duration,
    pub connection: Arc<futures::lock::Mutex<ImapConnection>>,
}

impl WatchJob {
    pub async fn watch<'a>(&'a self) -> Result<WatchReturnReason, MeliError> {
        let has_idle = {
            let conn = self.connection.lock().await;

            conn.has_capability("IDLE".to_string())
        };

        let has_idle = true; //@TODO capabiltiies are not updated proberly

        if !has_idle {
            debug!("Server does not support IDLE");

            debug!("IDLE-less support not implemented yet");

            return Err(MeliError::new("Non-IDLE servers not supported").set_kind(melib::error::ErrorKind::None));
        }

        loop {
            debug!("Server supports IDLE");
            match idle(
                create_connection(&self.server_conf, BackendEventConsumer::new(Arc::new(|_, _| {}))),
                self.idle_timeout_duration,
            )
            .await
            {
                Ok(IdleReturnReason::Updates(updates)) => {
                    return Ok(WatchReturnReason::Updates(updates));
                }
                Ok(IdleReturnReason::Timeout) => {
                    return Ok(WatchReturnReason::Timeout);
                }
                Err(network_error) if network_error.kind.is_network() => {
                    debug!("Watch network failure: {}", network_error.to_string());

                    let mut main_conn_lck = timeout(self.reconnect_timeout_duration, self.connection.lock()).await?;

                    match timeout(self.reconnect_timeout_duration, main_conn_lck.connect())
                        .await
                        .and_then(|res| res)
                    {
                        Err(reconnect_error) => {
                            debug!("Watch reconnect attempt failed: {}", reconnect_error.to_string());
                            return Err(reconnect_error);
                        }
                        Ok(()) => {
                            debug!("Watch reconnect attempt succesful");
                            continue;
                        }
                    }
                }
                Err(err) => return Err(err),
            }
        }
    }
}

#[derive(Debug, PartialEq)]
pub enum UntaggedResponse {
    Expunge(melib::backends::imap::MessageSequenceNumber),
    Exists(melib::backends::imap::ImapNum),
    Recent(melib::backends::imap::ImapNum),
    //@TODO
    Fetch,
    Bye(String),
}

fn process_untagged_line(line: &[u8]) -> Result<Option<UntaggedResponse>, String> {
    debug!("Processing untagged line: {}", std::str::from_utf8(&line).unwrap().trim());
    match melib::backends::imap::untagged_responses(line).map(|(_, v, _)| v) {
        Ok(None) => Ok(None),
        Err(_) => {
            // @TODO this should also be an error but melib parser can't parse strings like
            // "M5 OK IDLE terminated (Success)"
            Ok(None)
        }
        Ok(Some(parsed_response)) => match parsed_response {
            melib::backends::imap::UntaggedResponse::Expunge(x) => Ok(Some(UntaggedResponse::Expunge(x))),
            melib::backends::imap::UntaggedResponse::Exists(x) => Ok(Some(UntaggedResponse::Exists(x))),
            melib::backends::imap::UntaggedResponse::Recent(x) => Ok(Some(UntaggedResponse::Recent(x))),
            melib::backends::imap::UntaggedResponse::Fetch(_) => Ok(Some(UntaggedResponse::Fetch)),
            melib::backends::imap::UntaggedResponse::Bye { reason } => Ok(Some(UntaggedResponse::Bye(reason.to_string()))),
        },
    }
}

#[derive(Debug)]
pub enum IdleReturnReason {
    Timeout,
    Updates(Vec<UntaggedResponse>),
}

fn is_continuation_or_confirmation(line: &[u8]) -> bool {
    line.starts_with(b"+ ")
        || line.starts_with(b"* ok")
        || line.starts_with(b"* ok")
        || line.starts_with(b"* Ok")
        || line.starts_with(b"* OK")
}

async fn idle(connection: ImapConnection, timeout_duration: std::time::Duration) -> Result<IdleReturnReason, MeliError> {
    /* Idle on a given mailbox. Timeout after a specified duration. */
    let mut response = Vec::with_capacity(8 * 1024);

    let mut blocking_connection_wrapper = melib::backends::imap::ImapBlockingConnection::from(connection);
    blocking_connection_wrapper.conn.connect().await?;

    debug!("Sending IDLE");

    blocking_connection_wrapper.conn.send_command(b"SELECT INBOX").await?;
    blocking_connection_wrapper
        .conn
        .read_response(&mut response, RequiredResponses::empty())
        .await?;

    blocking_connection_wrapper.conn.send_command(b"IDLE").await?;

    loop {
        debug!("Waiting");
        match timeout(Some(timeout_duration), blocking_connection_wrapper.as_stream()).await {
            Ok(Some(lines)) => {
                debug!("Received responses after IDLE, processing");

                if lines.split_rn().filter(|line| !is_continuation_or_confirmation(line)).count() == 0 {
                    debug!("Responses where only command confirmations and continuation marks. Ignoring");

                    continue;
                }

                blocking_connection_wrapper.conn.send_raw(b"DONE").await?;
                blocking_connection_wrapper
                    .conn
                    .read_response(&mut response, RequiredResponses::empty())
                    .await?;

                let untagged_responses: Result<Vec<_>, _> = lines
                    .split_rn()
                    .chain(response.split_rn())
                    .filter(|line| {
                        let should_drop = is_continuation_or_confirmation(line);

                        if should_drop {
                            debug!(
                                "Dropping command confirmation or continuation: {}",
                                std::str::from_utf8(&line).unwrap().trim()
                            );
                        }

                        !should_drop
                    })
                    .map(process_untagged_line)
                    .filter_map(|untagged_response| match untagged_response {
                        // @TODO This match here is ugly and unnecessary but melib doesn't parse all the possible untagged responses right
                        // now
                        Err(x) => Some(Err(x)),
                        Ok(None) => None,
                        Ok(Some(x)) => Some(Ok(x)),
                    })
                    .collect();

                return Ok(IdleReturnReason::Updates(untagged_responses?));
            }
            Ok(None) => {
                debug!("IDLE connection dropped: {:?}", &blocking_connection_wrapper.err());
                // blockn.conn.connect().await?;
                // let mut main_conn_lck = timeout(uid_store.timeout,
                // main_conn.lock()).await?; main_conn_lck.connect().
                // await?; continue;
                return Err(MeliError::new("Connection dropped").set_kind(melib::error::ErrorKind::None));
            }
            Err(_) => {
                debug!("Timing out IDLE");

                blocking_connection_wrapper.conn.send_raw(b"DONE").await?;
                blocking_connection_wrapper
                    .conn
                    .read_response(&mut response, RequiredResponses::empty())
                    .await?;

                return Ok(IdleReturnReason::Timeout);
            }
        };
    }
}
