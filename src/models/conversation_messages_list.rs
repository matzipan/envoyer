use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use glib::subclass::Signal;
use glib::SignalHandlerId;
use glib::Value;

use std::cell::RefCell;
use std::ops::Fn;
use std::rc::Rc;

use crate::models;
use crate::services;

use once_cell::sync::Lazy;

pub mod model {
    use super::*;
    use row_data::MessageRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct ConversationModel {
            pub store: Rc<RefCell<Option<Rc<services::Store>>>>,
            pub message: Rc<RefCell<Option<models::Message>>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for ConversationModel {
            const NAME: &'static str = "Model";
            type Type = super::ConversationModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self {
                    store: Default::default(),
                    message: Default::default(),
                }
            }
        }

        impl ObjectImpl for ConversationModel {
            fn signals() -> &'static [Signal] {
                static SIGNALS: Lazy<Vec<Signal>> =
                    Lazy::new(|| vec![Signal::builder("is-loading").param_types(Some(bool::static_type())).build()]);
                SIGNALS.as_ref()
            }
        }

        impl ListModelImpl for ConversationModel {
            fn item_type(&self) -> glib::Type {
                MessageRowData::static_type()
            }
            fn n_items(&self) -> u32 {
                match &*self.message.as_ref().borrow() {
                    Some(_) => 1,
                    None => 0,
                }
            }
            fn item(&self, position: u32) -> Option<glib::Object> {
                let data = models::conversation_messages_list::row_data::MessageRowData::new();

                data.set_message(self.message.borrow().as_ref().unwrap().clone()); //@TODO should probably be an Rc to the item

                Some(data.clone().upcast::<glib::Object>())
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
            glib::Object::new::<ConversationModel>()
        }

        pub fn attach_store(self, store: Rc<services::Store>) {
            let self_ = imp::ConversationModel::from_instance(&self);

            self_.store.replace(Some(store));
        }

        pub fn load_message(&self, id: i32) {
            let self_ = imp::ConversationModel::from_instance(&self);

            let previous_count = self_.n_items();

            self_.message.replace(Some(
                self_
                    .store
                    .borrow()
                    .as_ref()
                    .unwrap()
                    .get_message(id)
                    .expect("Unable to get message"),
            ));

            let new_count = self_.n_items();

            self.items_changed(0, previous_count, new_count);
            self.emit_by_name::<()>("is-loading", &[&false]);
        }

        pub fn set_loading(&self) {
            self.emit_by_name::<()>("is-loading", &[&true]);
        }

        pub fn connect_is_loading<F>(&self, callback: F) -> SignalHandlerId
        where
            F: Fn(&[Value]) -> Option<Value> + 'static,
        {
            self.connect_local("is-loading", false, callback)
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
            glib::Object::new::<MessageRowData>()
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
