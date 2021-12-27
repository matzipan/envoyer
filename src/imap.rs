use crate::models;

use melib;
use melib::backends::imap::{
    list_mailbox_result, status_response, ImapConnection, ImapExtensionUse, ImapLineSplit, ImapMailbox, ImapProtocol::IMAP as ImapProtocol,
    ImapServerConf, MessageSequenceNumber, ModSequence, RequiredResponses, SyncPolicy, UIDStore,
};
use melib::backends::{BackendEventConsumer, MailboxHash, ResultFuture};
use melib::connections::timeout;
use melib::{BackendMailbox, MeliError};

use futures::lock::Mutex as FutureMutex;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime};

use std::convert::TryInto;
use std::time::Instant;

use log::debug;

#[derive(Debug)]
pub struct ImapBackend {
    connection: Arc<FutureMutex<ImapConnection>>,
    server_conf: ImapServerConf,
}

pub enum SyncType {
    // Return all messages in a mailbox
    Fresh,
    // Return all new messages that have a UID greater than max_uid and all flags for messages that have a UID less than or equal
    Update {
        max_uid: melib::backends::imap::UID,
        uid_validity: melib::backends::imap::UIDVALIDITY,
    },
}

pub struct MessageFlagUpdate {
    pub uid: melib::backends::imap::UID,
    pub flags: models::MessageFlags,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ImapFetchResponse {
    pub uid: Option<melib::backends::imap::UID>,
    pub message_sequence_number: MessageSequenceNumber,
    pub modseq: Option<ModSequence>,
    pub flags: Option<(melib::email::Flag, Vec<String>)>,
    pub body: Option<String>,
    pub references: Option<String>,
    pub envelope: Option<melib::email::Envelope>,
}

struct UidFetchIterator {
    uid_range_end: melib::backends::imap::UID,
    next_range_start: melib::backends::imap::UID,
    ended: bool,
}

impl UidFetchIterator {
    pub fn new(uid_range_start: melib::backends::imap::UID, uid_range_end: melib::backends::imap::UID) -> UidFetchIterator {
        UidFetchIterator {
            uid_range_end,
            next_range_start: uid_range_start,
            ended: false,
        }
    }

    pub fn chunk_size() -> melib::backends::imap::UID {
        250
    }
}

impl Iterator for UidFetchIterator {
    // We are doing the iteration ascendingly because if we stop mid-sync we can
    // still use max UID to resume the sync gracefully.
    type Item = (melib::backends::imap::UID, melib::backends::imap::UID);
    // The return type is `Option<T>`:
    //     * When the `Iterator` is finished, `None` is returned.
    //     * Otherwise, the next value is wrapped in `Some` and returned.
    fn next(&mut self) -> Option<(melib::backends::imap::UID, melib::backends::imap::UID)> {
        if self.next_range_start <= self.uid_range_end && !self.ended {
            let current_range_start = self.next_range_start;

            // Subtracting one to because the range is inclusive so we have to subtract one
            // if we want a length of chunk_size
            let current_range_end = std::cmp::min(
                current_range_start.saturating_add(UidFetchIterator::chunk_size() - 1),
                self.uid_range_end,
            );

            self.next_range_start = current_range_end.saturating_add(1);

            if current_range_end == melib::backends::imap::UID::max_value() {
                self.ended = true;
            }

            Some((current_range_start, current_range_end))
        } else {
            None
        }
    }
}

#[cfg(test)]
mod uid_fetch_iterator_tests {
    use super::*;
    #[test]
    fn test_uid_fetch_iterator_ranges() {
        let mut iterator = UidFetchIterator::new(1, 1000);

        assert_eq!(iterator.next(), Some((1, UidFetchIterator::chunk_size())));
        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() + 1, UidFetchIterator::chunk_size() * 2))
        );
        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() * 2 + 1, UidFetchIterator::chunk_size() * 3))
        );
        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() * 3 + 1, UidFetchIterator::chunk_size() * 4))
        );
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(1, 1);

        assert_eq!(iterator.next(), Some((1, 1)));
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(UidFetchIterator::chunk_size() - 20, UidFetchIterator::chunk_size());

        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() - 20, UidFetchIterator::chunk_size()))
        );
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(UidFetchIterator::chunk_size() - 20, UidFetchIterator::chunk_size() * 2 + 150);

        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() - 20, UidFetchIterator::chunk_size() * 2 - 20 - 1))
        );
        assert_eq!(
            iterator.next(),
            Some((UidFetchIterator::chunk_size() * 2 - 20, UidFetchIterator::chunk_size() * 2 + 150))
        );
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(1, 0);

        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(melib::backends::imap::UID::max_value(), 0);

        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(
            melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size() * 2 + 1,
            melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size() + 10,
        );

        assert_eq!(
            iterator.next(),
            Some((
                melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size() * 2 + 1,
                melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size()
            ))
        );
        assert_eq!(
            iterator.next(),
            Some((
                melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size() + 1,
                melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size() + 10
            ))
        );
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(
            melib::backends::imap::UID::max_value() - 20,
            melib::backends::imap::UID::max_value(),
        );

        assert_eq!(
            iterator.next(),
            Some((
                melib::backends::imap::UID::max_value() - 20,
                melib::backends::imap::UID::max_value()
            ))
        );
        assert_eq!(iterator.next(), None);

        let mut iterator = UidFetchIterator::new(
            melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size(),
            melib::backends::imap::UID::max_value(),
        );

        assert_eq!(
            iterator.next(),
            Some((
                melib::backends::imap::UID::max_value() - UidFetchIterator::chunk_size(),
                melib::backends::imap::UID::max_value() - 1
            ))
        );
        assert_eq!(
            iterator.next(),
            Some((melib::backends::imap::UID::max_value(), melib::backends::imap::UID::max_value()))
        );
        assert_eq!(iterator.next(), None);
    }
}

impl ImapBackend {
    pub fn new(
        server_hostname: String,
        server_port: u16,
        server_username: String,
        password: String,
        use_oauth2: bool,
        use_tls: bool,
        use_starttls: bool,
        danger_accept_invalid_certs: bool,
        event_consumer: BackendEventConsumer,
    ) -> Result<Box<ImapBackend>, MeliError> {
        let server_conf = ImapServerConf {
            server_hostname,
            server_username,
            server_password: password,
            server_port,
            use_tls,
            use_starttls,
            danger_accept_invalid_certs,
            protocol: ImapProtocol {
                extension_use: ImapExtensionUse {
                    idle: true,
                    condstore: true,
                    oauth2: use_oauth2,
                },
            },
            timeout: Some(Duration::from_secs(10)),
        };

        Ok(Box::new(ImapBackend {
            connection: Arc::new(FutureMutex::new(ImapConnection {
                stream: Err(MeliError::new("Offline".to_string())),
                server_conf: server_conf.clone(),
                sync_policy: SyncPolicy::Basic,
                uid_store: Arc::new(UIDStore::new(
                    0,
                    Arc::new("123".to_string()),
                    BackendEventConsumer::new(Arc::new(|_, _| {})),
                    server_conf.timeout,
                )),
                account_hash: 0,
                account_name: Arc::new("123".to_string()),
                capabilities: Default::default(),
                is_online: Arc::new(Mutex::new((SystemTime::now(), Err(MeliError::new("Account is uninitialised."))))),
                event_consumer: event_consumer,
            })),
            server_conf,
        }))
    }

    pub fn is_online(&self) -> ResultFuture<()> {
        let connection = self.connection.clone();
        let timeout_dur = self.server_conf.timeout;
        Ok(Box::pin(async move {
            match timeout(timeout_dur, connection.lock()).await {
                Ok(mut conn) => match timeout(timeout_dur, conn.connect()).await {
                    Ok(Ok(())) => Ok(()),
                    Err(err) | Ok(Err(err)) => {
                        conn.stream = Err(err.clone());
                        conn.connect().await
                    }
                },
                Err(err) => Err(err),
            }
        }))
    }

    pub fn mailboxes(&self) -> ResultFuture<HashMap<MailboxHash, Box<ImapMailbox>>> {
        let connection = self.connection.clone();
        Ok(Box::pin(async move {
            let mut mailboxes: HashMap<MailboxHash, ImapMailbox> = Default::default();
            let mut res = Vec::with_capacity(8 * 1024);
            let mut conn = connection.lock().await;

            if conn.has_capability("LIST-STATUS".to_string()) {
                conn.send_command(b"LIST \"\" \"*\" RETURN (STATUS (MESSAGES UNSEEN))").await?;
                conn.read_response(&mut res, RequiredResponses::LIST_REQUIRED | RequiredResponses::STATUS)
                    .await?;
            } else {
                conn.send_command(b"LIST \"\" \"*\"").await?;
                conn.read_response(&mut res, RequiredResponses::LIST_REQUIRED).await?;
            }

            for l in res.split_rn() {
                if !l.starts_with(b"*") {
                    continue;
                }
                if let Ok(mut mailbox) = list_mailbox_result(&l).map(|(_, v)| v) {
                    if let Some(parent) = mailbox.parent {
                        if mailboxes.contains_key(&parent) {
                            mailboxes.entry(parent).and_modify(|e| e.children.push(mailbox.hash));
                        } else {
                            /* Insert dummy parent entry, populating only the children field. Later
                             * when we encounter the parent entry we will swap its children with
                             * dummy's */
                            mailboxes.insert(
                                parent,
                                ImapMailbox {
                                    children: vec![mailbox.hash],
                                    ..ImapMailbox::default()
                                },
                            );
                        }
                    }
                    if mailboxes.contains_key(&mailbox.hash) {
                        let entry = mailboxes.entry(mailbox.hash).or_default();
                        std::mem::swap(&mut entry.children, &mut mailbox.children);
                        *entry = mailbox;
                    } else {
                        mailboxes.insert(mailbox.hash, mailbox);
                    }
                } else if let Ok(status) = status_response(&l).map(|(_, v)| v) {
                    if let Some(mailbox_hash) = status.mailbox {
                        if mailboxes.contains_key(&mailbox_hash) {
                            let entry = mailboxes.entry(mailbox_hash).or_default();
                            if let Some(total) = status.messages {
                                entry.exists.lock().unwrap().set_not_yet_seen(total);
                            }
                            if let Some(total) = status.unseen {
                                entry.unseen.lock().unwrap().set_not_yet_seen(total);
                            }
                        }
                    }
                } else {
                }
            }
            mailboxes.retain(|_, v| v.hash != 0);
            conn.send_command(b"LSUB \"\" \"*\"").await?;
            conn.read_response(&mut res, RequiredResponses::LSUB_REQUIRED).await?;

            for l in res.split_rn() {
                if !l.starts_with(b"*") {
                    continue;
                }
                if let Ok(subscription) = list_mailbox_result(&l).map(|(_, v)| v) {
                    if let Some(f) = mailboxes.get_mut(&subscription.hash()) {
                        if f.special_usage() == melib::backends::SpecialUsageMailbox::Normal
                            && subscription.special_usage() != melib::backends::SpecialUsageMailbox::Normal
                        {
                            f.set_special_usage(subscription.special_usage())?;
                        }
                        f.is_subscribed = true;
                    }
                } else {
                }
            }

            Ok(mailboxes.iter().map(|(h, f)| (*h, Box::new(Clone::clone(f)))).collect())
        }))
    }

    pub fn sync(
        &self,
        imap_path: String,
        sync_type: SyncType,
    ) -> ResultFuture<(
        melib::backends::imap::UIDVALIDITY,
        Vec<models::NewMessage>,
        Option<Vec<MessageFlagUpdate>>,
    )> {
        let connection_clone = self.connection.clone();
        let timeout_dur = self.server_conf.timeout;

        Ok(Box::pin(async move {
            let mut connection = timeout(timeout_dur, connection_clone.lock()).await?;

            let select_response = connection.select(imap_path.clone()).await?;

            let mut sync_type = sync_type;

            loop {
                match sync_type {
                    SyncType::Fresh => {
                        debug!("Doing a fresh fetch");

                        let now = Instant::now();

                        let new_messages = fetch_messages_overview_in_uid_range(&mut *connection, 1, select_response.uidnext - 1).await?;

                        debug!(
                            "Finished fresh fetch. Found {} new messages. Took {} seconds.",
                            new_messages.len(),
                            now.elapsed().as_secs()
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
                            debug!("UID Validity mismatch. Going for a fresh fetch");

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
        }))
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
