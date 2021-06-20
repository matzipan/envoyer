use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::models;

pub mod model {
    use super::*;
    use row_data::MessageRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct ConversationModel(pub RefCell<Vec<MessageRowData>>);
        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for ConversationModel {
            const NAME: &'static str = "Model";
            type Type = super::ConversationModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self(RefCell::new(Vec::new()))
            }
        }
        impl ObjectImpl for ConversationModel {}
        impl ListModelImpl for ConversationModel {
            fn item_type(&self, _list_model: &Self::Type) -> glib::Type {
                MessageRowData::static_type()
            }
            fn n_items(&self, _list_model: &Self::Type) -> u32 {
                self.0.borrow().len() as u32
            }
            fn item(&self, _list_model: &Self::Type, position: u32) -> Option<glib::Object> {
                self.0.borrow().get(position as usize).map(|o| o.clone().upcast::<glib::Object>())
            }
        }
    }
    // Public part of the Model type.
    glib::wrapper! {
        pub struct ConversationModel(ObjectSubclass<imp::ConversationModel>) @implements gio::ListModel;
    }
    // Constructor for new instances. This simply calls glib::Object::new()
    impl ConversationModel {
        #[allow(clippy::new_without_default)]
        pub fn new() -> ConversationModel {
            glib::Object::new(&[]).expect("Failed to create ConversationModel")
        }
        pub fn append(&self, obj: &MessageRowData) {
            let self_ = imp::ConversationModel::from_instance(self);
            let index = {
                // Borrow the data only once and ensure the borrow guard is dropped
                // before we emit the items_changed signal because the view
                // could call get_item / get_n_item from the signal handler to update its state
                let mut data = self_.0.borrow_mut();
                data.push(obj.clone());
                data.len() - 1
            };
            // Emits a signal that 1 item was added, 0 removed at the position index
            self.items_changed(index as u32, 0, 1);
        }
        pub fn remove(&self, index: u32) {
            let self_ = imp::ConversationModel::from_instance(self);
            self_.0.borrow_mut().remove(index as usize);
            // Emits a signal that 1 item was removed, 0 added at the position index
            self.items_changed(index, 1, 0);
        }

        pub fn remove_all(&self) {
            let self_ = imp::ConversationModel::from_instance(self);

            let mut messages_list = self_.0.borrow_mut();

            let number_of_items = messages_list.len();

            messages_list.clear();

            // Emits a signal that all item were removed, 0 added at the position index
            self.items_changed(0, number_of_items as u32, 0);
        }
    }
}

// This row data wrapper is needed because the ConversationModel get_item_type
// method needs to have a GObject type to return to the bind_model method
pub mod row_data {
    use super::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct MessageRowData {
            pub message: Rc<RefCell<Option<models::Message>>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for MessageRowData {
            const NAME: &'static str = "MessageRowData";
            type Type = super::MessageRowData;
            type ParentType = glib::Object;
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    message: Default::default(),
                }
            }
        }
        impl ObjectImpl for MessageRowData {}
    }

    // The public part
    glib::wrapper! {
        pub struct MessageRowData(ObjectSubclass<imp::MessageRowData>);
    }
    impl MessageRowData {
        pub fn new() -> MessageRowData {
            glib::Object::new(&[]).expect("Failed to create row data")
        }
        pub fn set_message(&self, message: models::Message) {
            let self_ = imp::MessageRowData::from_instance(self);
            self_.message.replace(Some(message));
        }
        pub fn get_message(&self) -> Rc<RefCell<Option<models::Message>>> {
            let self_ = imp::MessageRowData::from_instance(self);
            self_.message.clone()
        }
    }
}
