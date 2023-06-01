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
    use row_data::FolderRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct FolderListModel {
            pub store: Rc<RefCell<Option<Arc<services::Store>>>>,
            pub folders: Rc<RefCell<Vec<models::Folder>>>,
            pub bare_identities: Rc<RefCell<Vec<models::BareIdentity>>>,
        }

        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for FolderListModel {
            const NAME: &'static str = "FolderListModel";
            type Type = super::FolderListModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self {
                    store: Default::default(),
                    folders: Default::default(),
                    bare_identities: Default::default(),
                }
            }
        }
        impl ObjectImpl for FolderListModel {}
        impl ListModelImpl for FolderListModel {
            fn item_type(&self) -> glib::Type {
                FolderRowData::static_type()
            }
            fn n_items(&self) -> u32 {
                self.folders.borrow().len() as u32
            }
            fn item(&self, position: u32) -> Option<glib::Object> {
                self.folders.borrow().get(position as usize).map(|x| {
                    let data = FolderRowData::new();

                    data.set_folder(x.clone()); //@TODO should probably be an arc to the item

                    data.clone().upcast::<glib::Object>()
                })
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
            glib::Object::new()
        }

        pub fn attach_store(self, store: Arc<services::Store>) {
            let self_ = imp::FolderListModel::from_instance(&self);

            self_.store.replace(Some(store));
        }

        pub fn load(&self) {
            let self_ = imp::FolderListModel::from_instance(self);

            let previous_count = self_.n_items();

            self_.bare_identities.replace(
                self_
                    .store
                    .borrow()
                    .as_ref()
                    .unwrap()
                    .get_bare_identities()
                    .expect("Unable to get bare identities"),
            );

            // @TODO add support for multiple identities
            self_.folders.replace(
                self_
                    .store
                    .borrow()
                    .as_ref()
                    .unwrap()
                    .get_folders(&self_.bare_identities.borrow()[0])
                    .expect("Unable to get folders"),
            );

            let new_count = self_.n_items();

            self.items_changed(0, previous_count, new_count);
        }
    }
}

// This row data wrapper is needed because the FolderListModel get_item_type
// method needs to have a GObject type to return to the bind_model method
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
            glib::Object::new::<FolderRowData>()
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
