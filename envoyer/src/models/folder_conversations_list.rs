use gtk::{gio, glib};

use glib::subclass;

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::models;

pub mod model {
    use super::*;
    use row_data::ConversationRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct Model(pub RefCell<Vec<ConversationRowData>>);
        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for Model {
            const NAME: &'static str = "Model";
            type Type = super::Model;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self(RefCell::new(Vec::new()))
            }
        }
        impl ObjectImpl for Model {}
        impl ListModelImpl for Model {
            fn get_item_type(&self, _list_model: &Self::Type) -> glib::Type {
                ConversationRowData::static_type()
            }
            fn get_n_items(&self, _list_model: &Self::Type) -> u32 {
                self.0.borrow().len() as u32
            }
            fn get_item(&self, _list_model: &Self::Type, position: u32) -> Option<glib::Object> {
                self.0.borrow().get(position as usize).map(|o| o.clone().upcast::<glib::Object>())
            }
        }
    }
    // Public part of the Model type.
    glib::wrapper! {
        pub struct Model(ObjectSubclass<imp::Model>) @implements gio::ListModel;
    }
    // Constructor for new instances. This simply calls glib::Object::new()
    impl Model {
        #[allow(clippy::new_without_default)]
        pub fn new() -> Model {
            glib::Object::new(&[]).expect("Failed to create Model")
        }
        pub fn append(&self, obj: &ConversationRowData) {
            let self_ = imp::Model::from_instance(self);
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
            let self_ = imp::Model::from_instance(self);
            self_.0.borrow_mut().remove(index as usize);
            // Emits a signal that 1 item was removed, 0 added at the position index
            self.items_changed(index, 1, 0);
        }
    }
}

// This row data wrapper is needed because the Model get_item_type method needs
// to have a GObject type to return to the bind_model method
pub mod row_data {
    use super::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct ConversationRowData {
            pub conversation: Rc<RefCell<Option<models::Message>>>,
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
        pub fn set_conversation(&self, conversation: models::Message) {
            let self_ = imp::ConversationRowData::from_instance(self);
            self_.conversation.replace(Some(conversation));
        }
        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::Message>>> {
            let self_ = imp::ConversationRowData::from_instance(self);
            self_.conversation.clone()
        }
    }
}
