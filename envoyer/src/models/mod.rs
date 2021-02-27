mod database;
mod identity;

pub use database::{BareIdentity, Folder, IdentityType, Message, MessageFlags, NewBareIdentity, NewFolder, NewMessage};
pub use identity::Identity;
