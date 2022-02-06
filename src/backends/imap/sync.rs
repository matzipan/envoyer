use super::*;

use crate::models;

use melib::backends::imap::ImapConnection;

use melib::connections::timeout;

use melib::MeliError;

use log::debug;

use futures::Future;

use std::convert::TryInto;
use std::sync::Arc;
use std::time::Duration;
use std::time::Instant;

pub struct SyncJob {
    pub imap_path: String,
    pub initial_sync_type: SyncType,
    pub connect_timeout_duration: Option<Duration>,
    pub connection: Arc<futures::lock::Mutex<ImapConnection>>,
}

impl SyncJob {
    pub fn sync<'a>(
        &'a self,
    ) -> impl Future<
        Output = Result<
            (
                melib::backends::imap::UIDVALIDITY,
                Vec<models::NewMessage>,
                Option<Vec<MessageFlagUpdate>>,
            ),
            MeliError,
        >,
    > + 'a {
        async move {
            let mut connection = timeout(self.connect_timeout_duration, self.connection.lock()).await?;

            let select_response = connection.select(self.imap_path.clone()).await?;

            let mut sync_type = self.initial_sync_type.clone();

            loop {
                match sync_type {
                    SyncType::Fresh => {
                        debug!("Doing a fresh fetch");

                        let now = Instant::now();

                        let new_messages = fetch_messages_overview_in_uid_range(&mut *connection, 1, select_response.uidnext - 1).await?;

                        debug!(
                            "Finished fresh fetch. Found {} new messages with UID validity {}. Took {} seconds.",
                            new_messages.len(),
                            select_response.uidvalidity,
                            now.elapsed().as_millis() as f32 / 1000.0
                        );
                        return Ok((select_response.uidvalidity, new_messages, None));
                    }
                    SyncType::Update {
                        max_uid,
                        uid_validity: old_uid_validity,
                    } => {
                        debug!(
                            "Updating with max_uid {}, old uid_validity {} and new uid_validity {}",
                            max_uid, old_uid_validity, select_response.uidvalidity
                        );

                        let now = Instant::now();

                        if select_response.uidvalidity != old_uid_validity {
                            debug!(
                                "UID Validity mismatch between {} and {}. Going for a fresh fetch",
                                select_response.uidvalidity, old_uid_validity
                            );

                            sync_type = SyncType::Fresh;
                            continue;
                        } else if select_response.exists == 0 {
                            debug!("No messages in the mailbox");

                            //@TODO return response
                            return Ok((select_response.uidvalidity, Vec::new(), None));
                        } else {
                            debug!("Fetching new messages");
                            let new_messages =
                                fetch_messages_overview_in_uid_range(&mut *connection, max_uid + 1, select_response.uidnext - 1).await?;

                            debug!("Found {} new messages. Fetching flag updates", new_messages.len());
                            let flag_updates = fetch_flags_updates_in_uid_range(&mut *connection, 1, max_uid).await?;

                            debug!("Finished in {} seconds.", now.elapsed().as_secs());

                            return Ok((select_response.uidvalidity, new_messages, Some(flag_updates)));
                        }
                    }
                };
            }
        }
    }
}

async fn fetch_flags_updates_in_uid_range(
    connection: &mut melib::imap::ImapConnection,
    uid_range_start: melib::imap::UID,
    uid_range_end: melib::imap::UID,
) -> Result<Vec<MessageFlagUpdate>, MeliError> {
    let mut response = Vec::with_capacity(8 * 1024);

    let mut messages = connection
        .uid_fetch(format!("{}:{}", uid_range_start, uid_range_end), "FLAGS".to_string(), &mut response)
        .await?;

    let mut flag_updates_list = Vec::new();

    for message in messages.iter_mut() {
        let (flags, tags) = message.flags.as_ref().unwrap();

        //@TODO tags

        flag_updates_list.push(MessageFlagUpdate {
            uid: message.uid.unwrap(),
            flags: models::MessageFlags {
                seen: flags.contains(melib::email::Flag::SEEN),
                flagged: flags.contains(melib::email::Flag::FLAGGED),
                draft: flags.contains(melib::email::Flag::DRAFT),
                deleted: flags.contains(melib::email::Flag::TRASHED),
            },
        });
    }

    Ok(flag_updates_list)
}

async fn fetch_messages_overview_in_uid_range(
    connection: &mut melib::imap::ImapConnection,
    uid_range_start: melib::imap::UID,
    uid_range_end: melib::imap::UID,
) -> Result<Vec<models::NewMessage>, MeliError> {
    //@TODO asyncstream

    let mut response = Vec::with_capacity(8 * 1024);
    let mut messages_list = Vec::new();

    let mut iterator = UidFetchIterator::new(uid_range_start, uid_range_end);

    while let Some((fetch_range_start, fetch_range_end)) = iterator.next() {
        let mut messages = connection
            .uid_fetch(
                format!("{}:{}", fetch_range_start, fetch_range_end),
                "(UID FLAGS ENVELOPE)".to_string(),
                &mut response,
            )
            .await?;

        for message in messages.iter_mut() {
            let uid = message.uid.unwrap();
            let env = message.envelope.as_mut().unwrap();

            if let Some(value) = message.references {
                let parse_result = melib::email::parser::address::msg_id_list(value);
                if let Ok((_, value)) = parse_result {
                    let prev_val = env.references.take();
                    for v in value {
                        env.push_references(v);
                    }
                    if let Some(prev) = prev_val {
                        for v in prev.refs {
                            env.push_references(v);
                        }
                    }
                }
                env.set_references(value);
            }

            //@TODO
            let mut new_message = models::NewMessage::from(message.envelope.as_ref().unwrap().clone());

            //@TODO Fix conversion from u32 to i32
            new_message.uid = uid.try_into().unwrap();
            //     message_sequence_number: 0,
            //     references: None,

            //@TODO conversion from i64 to u64
            new_message.modification_sequence = message.modseq.unwrap().0.get().try_into().unwrap();

            messages_list.push(new_message);
        }
    }

    Ok(messages_list)
}
