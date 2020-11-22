use crate::schema::{folders, identities, messages};
use chrono;

#[derive(Identifiable, Queryable, Associations)]
#[belongs_to(BareIdentity, foreign_key = "identity_id")]
pub struct Folder {
    pub id: i32,
    pub folder_name: String,
    pub identity_id: i32,
    pub flags: i32,
}

#[derive(Insertable, Associations)]
#[belongs_to(BareIdentity, foreign_key = "identity_id")]
#[table_name = "folders"]
pub struct NewFolder {
    pub folder_name: String,
    pub identity_id: i32,
    pub flags: i32,
}

#[derive(Identifiable, Queryable, Associations)]
#[belongs_to(Folder)]
pub struct Message {
    pub id: i32,
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
    pub uid: i32,
    pub modification_sequence: i32,
    pub seen: bool,
    pub flagged: bool,
    pub draft: bool,
    pub deleted: bool,
    pub content: String,
}

#[derive(Insertable, Associations)]
#[belongs_to(Folder)]
#[table_name = "messages"]
pub struct NewMessage {
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
    pub uid: i32,
    pub modification_sequence: i32,
    pub seen: bool,
    pub flagged: bool,
    pub draft: bool,
    pub deleted: bool,
    pub content: String,
}

#[derive(Debug, AsExpression, FromSqlRow)]
#[sql_type = "diesel::sql_types::Text"]
pub enum IdentityType {
    Gmail,
}

impl<DB> diesel::deserialize::FromSql<diesel::sql_types::Text, DB> for IdentityType
where
    DB: diesel::backend::Backend,
    String: diesel::deserialize::FromSql<diesel::sql_types::Text, DB>,
{
    fn from_sql(bytes: Option<&DB::RawValue>) -> diesel::deserialize::Result<Self> {
        let deserialized = String::from_sql(bytes).expect("Unable to deserialize corrupt identity type");
        match deserialized.as_ref() {
            "Gmail" => Ok(IdentityType::Gmail),
            x => Err(format!("Unrecognized identity type {}", x).into()),
        }
    }
}

impl<DB> diesel::serialize::ToSql<diesel::sql_types::Text, DB> for IdentityType
where
    DB: diesel::backend::Backend,
    String: diesel::serialize::ToSql<diesel::sql_types::Text, DB>,
{
    fn to_sql<W: std::io::Write>(&self, out: &mut diesel::serialize::Output<W, DB>) -> diesel::serialize::Result {
        let serialized = match *self {
            IdentityType::Gmail => "Gmail",
        };

        String::to_sql(&serialized.to_owned(), out)
    }
}

#[derive(Identifiable, Queryable)]
#[table_name = "identities"]
pub struct BareIdentity {
    pub id: i32,
    pub email_address: String,
    pub gmail_refresh_token: String,
    pub identity_type: IdentityType,
    pub expires_at: chrono::NaiveDateTime,
    pub full_name: String,
    pub account_name: String,
}

#[derive(Insertable)]
#[table_name = "identities"]
pub struct NewBareIdentity<'a> {
    pub email_address: &'a String,
    pub gmail_refresh_token: &'a String,
    pub identity_type: IdentityType,
    pub expires_at: &'a chrono::NaiveDateTime,
    pub full_name: &'a String,
    pub account_name: &'a String,
}
