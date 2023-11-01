use crate::schema::{folders, identities, messages};
use chrono;

#[derive(Identifiable, Queryable, Associations, Debug, Clone)]
#[diesel(belongs_to(BareIdentity, foreign_key = identity_id))]
pub struct Folder {
    pub id: i32,
    pub folder_name: String,
    pub folder_path: String,
    pub identity_id: i32,
    pub uid_validity: Option<i64>,
    pub flags: i32,
}

#[derive(Insertable, Associations, Debug)]
#[diesel(belongs_to(BareIdentity, foreign_key = identity_id))]
#[diesel(table_name = folders)]
pub struct NewFolder {
    pub folder_name: String,
    pub folder_path: String,
    pub identity_id: i32,
    pub flags: i32,
}

#[derive(Identifiable, Queryable, Associations, Debug, Clone)]
#[diesel(belongs_to(Folder))]
pub struct Message {
    pub id: i32,
    pub message_id: String,
    pub subject: String,
    pub folder_id: i32,
    pub time_received: chrono::NaiveDateTime,
    pub from: String,
    pub to: String,
    pub cc: String,
    pub bcc: String,
    pub content: Option<String>,
    pub references: String,
    pub in_reply_to: String,
    pub uid: i64,
    pub modification_sequence: i64,
    pub seen: bool,
    pub flagged: bool,
    pub draft: bool,
    pub deleted: bool,
}

impl Message {
    pub fn get_time_received_utc(&self) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(self.time_received, chrono::Utc)
    }

    pub fn get_relative_time_ago(&self) -> String {
        chrono_humanize::HumanTime::from(self.get_time_received_utc())
            .to_text_en(chrono_humanize::Accuracy::Rough, chrono_humanize::Tense::Past)
    }
}

use smallvec::SmallVec;

impl From<Message> for melib::email::Envelope {
    fn from(message: Message) -> Self {
        let mut envelope = Self {
            hash: message.id as u64, //@TODO
            date: String::new(),
            timestamp: message.time_received.timestamp() as u64, //@TODO
            from: SmallVec::new(),
            to: SmallVec::new(),
            cc: SmallVec::new(), //@TODO
            bcc: Vec::new(),     //@TODO
            subject: Some(message.subject),
            message_id: melib::parser::address::msg_id(message.message_id.as_bytes()).unwrap().1, //@TODO
            in_reply_to: None,                                                                    //@TODO
            references: None,                                                                     //@TODO
            other_headers: Default::default(),                                                    //@TODO
            thread: melib::thread::ThreadNodeHash::null(),
            has_attachments: false,               //@TODO
            flags: melib::email::Flag::default(), //@TODO
            labels: SmallVec::new(),              //@TODO
        };

        // from: melib::parser::address::rfc2822address_list(&message.from.as_bytes()).
        // unwrap().1, to:
        // melib::parser::address::rfc2822address_list(&message.to.as_bytes()).unwrap().
        // 1,

        // cc: melib::parser::address::rfc2822address_list(&message.cc.as_bytes()).
        // unwrap().1, bcc: melib::parser::address::rfc2822address_list(&
        // message.bcc.as_bytes())     .unwrap()
        //     .1
        //     .to_vec(),
        // in_reply_to:
        // Some(melib::parser::address::msg_id(message.in_reply_to.as_bytes()).unwrap().
        // 1),

        {
            let parse_result = melib::parser::address::msg_id_list(message.references.as_bytes());
            if let Ok((_, value)) = parse_result {
                for v in value {
                    envelope.push_references(v);
                }
            }
        }
        envelope.set_references(message.references.as_bytes());

        envelope
    }
}

#[derive(Identifiable, Queryable, Debug, Clone)]
#[diesel(table_name = messages)]
pub struct MessageSummary {
    pub id: i32,
    pub message_id: String,
    pub subject: String,
    pub from: String,
    pub time_received: chrono::NaiveDateTime,
}

impl MessageSummary {
    pub fn get_time_received_utc(&self) -> chrono::DateTime<chrono::Utc> {
        chrono::DateTime::<chrono::Utc>::from_utc(self.time_received, chrono::Utc)
    }

    pub fn get_relative_time_ago(&self) -> String {
        chrono_humanize::HumanTime::from(self.get_time_received_utc())
            .to_text_en(chrono_humanize::Accuracy::Rough, chrono_humanize::Tense::Past)
    }
}

#[derive(AsChangeset, Debug, Clone)]
#[diesel(table_name = messages)]
pub struct MessageFlags {
    pub seen: bool,
    pub flagged: bool,
    pub draft: bool,
    pub deleted: bool,
}

#[derive(Insertable, Associations, Debug)]
#[diesel(belongs_to(Folder))]
#[diesel(table_name = messages)]
pub struct NewMessage {
    pub id: Option<i32>,
    pub message_id: String,
    pub folder_id: i32,
    pub subject: String,
    pub time_received: chrono::NaiveDateTime,
    pub from: String,
    pub to: String,
    pub cc: String,
    pub bcc: String,
    pub references: String,
    pub in_reply_to: String,
    pub uid: i64,
    pub modification_sequence: i64,
    pub seen: bool,
    pub flagged: bool,
    pub draft: bool,
    pub deleted: bool,
}

impl From<melib::email::Envelope> for NewMessage {
    fn from(envelope: melib::email::Envelope) -> Self {
        let flags = envelope.flags();

        NewMessage {
            id: None,
            message_id: String::from_utf8(envelope.message_id().0.clone()).unwrap(),
            folder_id: 0,
            subject: String::from(envelope.subject()),
            // We go straight for try_into().unwrap() because we know the timestamp won't take 64 bits any time soon
            time_received: chrono::NaiveDateTime::from_timestamp_opt(envelope.datetime() as i64, 0).expect("Invalid date time"), //@TODO
            from: envelope.field_from_to_string(),
            to: envelope.field_to_to_string(),
            cc: envelope.field_cc_to_string(),
            bcc: envelope.field_bcc_to_string(),
            references: envelope.field_references_to_string(),
            in_reply_to: envelope
                .in_reply_to()
                .map_or("".to_string(), |x| String::from_utf8(x.0.clone()).unwrap()),
            uid: 0,                   //@TODO
            modification_sequence: 0, //@TODO
            seen: flags.contains(melib::email::Flag::SEEN),
            flagged: flags.contains(melib::email::Flag::FLAGGED),
            draft: flags.contains(melib::email::Flag::DRAFT),
            deleted: flags.contains(melib::email::Flag::TRASHED),
            // REPLIED flag?
        }
    }
}

#[derive(PartialEq, Debug, AsExpression, FromSqlRow, Clone)]
#[diesel(sql_type = diesel::sql_types::Text)]
pub enum IdentityType {
    Gmail,
    Imap,
}

impl<DB> diesel::deserialize::FromSql<diesel::sql_types::Text, DB> for IdentityType
where
    DB: diesel::backend::Backend,
    String: diesel::deserialize::FromSql<diesel::sql_types::Text, DB>,
{
    fn from_sql(bytes: DB::RawValue<'_>) -> diesel::deserialize::Result<Self> {
        let deserialized = String::from_sql(bytes).expect("Unable to deserialize corrupt identity type");
        match deserialized.as_ref() {
            "Gmail" => Ok(IdentityType::Gmail),
            "Imap" => Ok(IdentityType::Imap),
            x => Err(format!("Unrecognized identity type {}", x).into()),
        }
    }
}

impl diesel::serialize::ToSql<diesel::sql_types::Text, diesel::sqlite::Sqlite> for IdentityType
where
    String: diesel::serialize::ToSql<diesel::sql_types::Text, diesel::sqlite::Sqlite>,
{
    fn to_sql<'b>(&'b self, out: &mut diesel::serialize::Output<'b, '_, diesel::sqlite::Sqlite>) -> diesel::serialize::Result {
        match *self {
            IdentityType::Gmail => out.set_value("Gmail".to_owned()),
            IdentityType::Imap => out.set_value("Imap".to_owned()),
        };

        Ok(diesel::serialize::IsNull::No)
    }
}

#[derive(Identifiable, Queryable, Debug, Clone)]
#[diesel(table_name = identities)]
pub struct BareIdentity {
    pub id: i32,
    pub email_address: String,
    pub identity_type: IdentityType,
    pub full_name: String,
    pub account_name: String,
    pub imap_server_hostname: String,
    // Ports are u16 but diesel doesn't have out of the box support for u16 so it's simpler
    pub imap_server_port: i32,
    pub imap_password: Option<String>,
    pub imap_use_tls: bool,
    pub imap_use_starttls: bool,
    pub gmail_refresh_token: String,
    pub expires_at: chrono::NaiveDateTime,
}

#[derive(Insertable, Debug)]
#[diesel(table_name = identities)]
pub struct NewBareIdentity<'a> {
    pub email_address: &'a String,
    pub identity_type: IdentityType,
    pub full_name: &'a String,
    pub account_name: &'a String,
    pub imap_server_hostname: &'a String,
    // Ports are u16 but diesel doesn't have out of the box support for u16 so it's simpler
    pub imap_server_port: i32,
    pub imap_password: Option<&'a String>,
    pub imap_use_tls: bool,
    pub imap_use_starttls: bool,
    pub gmail_refresh_token: &'a String,
    pub expires_at: &'a chrono::NaiveDateTime, //@TODO is this for refresh token or for access token?
}
