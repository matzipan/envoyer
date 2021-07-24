use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::models;

pub mod model {
    use super::*;
    use row_data::FolderRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct FolderListModel(pub RefCell<Vec<FolderRowData>>);
        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for FolderListModel {
            const NAME: &'static str = "FolderListModel";
            type Type = super::FolderListModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self(RefCell::new(Vec::new()))
            }
        }
        impl ObjectImpl for FolderListModel {}
        impl ListModelImpl for FolderListModel {
            fn item_type(&self, _list_model: &Self::Type) -> glib::Type {
                FolderRowData::static_type()
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
        pub struct FolderListModel(ObjectSubclass<imp::FolderListModel>) @implements gio::ListModel;
    }
    // Constructor for new instances. This simply calls glib::Object::new()
    impl FolderListModel {
        #[allow(clippy::new_without_default)]
        pub fn new() -> FolderListModel {
            glib::Object::new(&[]).expect("Failed to create FolderListModel")
        }
        pub fn append(&self, obj: &FolderRowData) {
            let self_ = imp::FolderListModel::from_instance(self);
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
            let self_ = imp::FolderListModel::from_instance(self);
            self_.0.borrow_mut().remove(index as usize);
            // Emits a signal that 1 item was removed, 0 added at the position index
            self.items_changed(index, 1, 0);
        }
    }
}

// This row data wrapper is needed because the FolderListModel get_item_type method
// needs to have a GObject type to return to the bind_model method
pub mod row_data {
    use super::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct FolderRowData {
            pub folder: Rc<RefCell<Option<models::Folder>>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for FolderRowData {
            const NAME: &'static str = "FolderRowData";
            type Type = super::FolderRowData;
            type ParentType = glib::Object;
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    folder: Default::default(),
                }
            }
        }
        impl ObjectImpl for FolderRowData {}
    }

    // The public part
    glib::wrapper! {
        pub struct FolderRowData(ObjectSubclass<imp::FolderRowData>);
    }
    impl FolderRowData {
        pub fn new() -> FolderRowData {
            glib::Object::new(&[]).expect("Failed to create row data")
        }
        pub fn set_folder(&self, folder: models::Folder) {
            let self_ = imp::FolderRowData::from_instance(self);
            self_.folder.replace(Some(folder));
        }
        pub fn get_folder(&self) -> Rc<RefCell<Option<models::Folder>>> {
            let self_ = imp::FolderRowData::from_instance(self);
            self_.folder.clone()
        }
    }
}
