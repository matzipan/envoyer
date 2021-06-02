mod database;
pub mod folder_conversations_list;
mod identity;

pub use database::{BareIdentity, Folder, IdentityType, Message, MessageFlags, NewBareIdentity, NewFolder, NewMessage};
pub use identity::Identity;
