use gtk::{gio, glib};

pub mod model {
    use super::*;
    use glib::subclass::prelude::*;
    use gtk::prelude::*;
    use gtk::subclass::prelude::*;
    use row_data::RowData;
    mod imp {
        use super::*;
        use glib::subclass;
        use std::cell::RefCell;
        #[derive(Debug)]
        pub struct Model(pub RefCell<Vec<RowData>>);
        // Basic declaration of our type for the GObject type system
        impl ObjectSubclass for Model {
            const NAME: &'static str = "Model";
            type Type = super::Model;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);
            type Instance = subclass::simple::InstanceStruct<Self>;
            type Class = subclass::simple::ClassStruct<Self>;
            glib::object_subclass!();
            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self(RefCell::new(Vec::new()))
            }
        }
        impl ObjectImpl for Model {}
        impl ListModelImpl for Model {
            fn get_item_type(&self, _list_model: &Self::Type) -> glib::Type {
                RowData::static_type()
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
        pub fn append(&self, obj: &RowData) {
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

pub mod row_data {
    use super::*;
    use glib::subclass;
    use glib::subclass::prelude::*;
    // Implementation sub-module of the GObject
    mod imp {
        use super::*;
        use std::cell::RefCell;
        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct RowData {
            pub subject: RefCell<Option<String>>,
        }
        // Basic declaration of our type for the GObject type system
        impl ObjectSubclass for RowData {
            const NAME: &'static str = "RowData";
            type Type = super::RowData;
            type ParentType = glib::Object;
            type Interfaces = ();
            type Instance = subclass::simple::InstanceStruct<Self>;
            type Class = subclass::simple::ClassStruct<Self>;
            glib::object_subclass!();
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    subject: Default::default(),
                }
            }
        }
        impl ObjectImpl for RowData {}
    }
    // The public part
    glib::wrapper! {
        pub struct RowData(ObjectSubclass<imp::RowData>);
    }
    impl RowData {
        pub fn new() -> RowData {
            glib::Object::new(&[]).expect("Failed to create row data")
        }
        pub fn set_subject(&self, subject: &String) {
            let self_ = imp::RowData::from_instance(self);
            self_.subject.replace(Some(subject.clone()));
        }
        pub fn get_subject(&self) -> String {
            let self_ = imp::RowData::from_instance(self);
            self_.subject.borrow().as_ref().unwrap().to_string()
        }
    }
}
