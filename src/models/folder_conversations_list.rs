use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;

use crate::models;
use crate::services;

pub mod model {
    use super::*;
    use row_data::ConversationRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct FolderModel {
            pub store: Rc<RefCell<Option<Arc<services::Store>>>>,
            pub summaries: Rc<RefCell<Option<Vec<models::MessageSummary>>>>,
        }
        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for FolderModel {
            const NAME: &'static str = "FolderModel";
            type Type = super::FolderModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self {
                    store: Default::default(),
                    summaries: Default::default(),
                }
            }
        }
        impl ObjectImpl for FolderModel {}
        impl ListModelImpl for FolderModel {
            fn item_type(&self, _list_model: &Self::Type) -> glib::Type {
                ConversationRowData::static_type()
            }

            fn n_items(&self, _list_model: &Self::Type) -> u32 {
                match self.summaries.borrow().as_ref() {
                    Some(summaries) => summaries.len() as u32,
                    None => 0,
                }
            }

            fn item(&self, _list_model: &Self::Type, position: u32) -> Option<glib::Object> {
                let data = ConversationRowData::new();

                data.set_conversation(self.summaries.borrow().as_ref().unwrap()[position as usize].clone()); //@TODO should probably be an arc to the item

                Some(data.clone().upcast::<glib::Object>())
            }
        }
    }
    // Public part of the Model type.
    glib::wrapper! {
        pub struct FolderModel(ObjectSubclass<imp::FolderModel>) @implements gio::ListModel;
    }
    // Constructor for new instances. This simply calls glib::Object::new()
    impl FolderModel {
        #[allow(clippy::new_without_default)]
        pub fn new() -> FolderModel {
            glib::Object::new(&[]).expect("Failed to create FolderModel")
        }

        pub fn attach_store(self, store: Arc<services::Store>) {
            let self_ = imp::FolderModel::from_instance(&self);

            self_.store.replace(Some(store));
        }

        pub fn load_folder(self, folder: models::Folder) {
            let self_ = imp::FolderModel::from_instance(&self);

            let previous_count = self_.n_items(&self);

            self_.summaries.replace(Some(
                self_
                    .store
                    .borrow()
                    .as_ref()
                    .unwrap()
                    .get_message_summaries_for_folder(&folder)
                    .expect("Unable to get message summary"),
            ));

            let new_count = self_.n_items(&self);

            self.items_changed(0, previous_count, new_count);
        }
    }
}

// This row data wrapper is needed because the FolderModel get_item_type method
// needs to have a GObject type to return to the bind_model method
pub mod row_data {
    use super::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct ConversationRowData {
            pub conversation: Rc<RefCell<Option<models::MessageSummary>>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for ConversationRowData {
            const NAME: &'static str = "ConversationRowData";
            type Type = super::ConversationRowData;
            type ParentType = glib::Object;
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    conversation: Default::default(),
                }
            }
        }
        impl ObjectImpl for ConversationRowData {}
    }

    // The public part
    glib::wrapper! {
        pub struct ConversationRowData(ObjectSubclass<imp::ConversationRowData>);
    }
    impl ConversationRowData {
        pub fn new() -> ConversationRowData {
            glib::Object::new(&[]).expect("Failed to create row data")
        }
        pub fn set_conversation(&self, conversation: models::MessageSummary) {
            let self_ = imp::ConversationRowData::from_instance(self);
            self_.conversation.replace(Some(conversation));
        }
        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
            let self_ = imp::ConversationRowData::from_instance(self);
            self_.conversation.clone()
        }
    }
}
