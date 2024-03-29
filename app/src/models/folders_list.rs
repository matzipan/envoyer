use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::models;
use crate::services;

use super::Folder;

enum FolderType {
    Inbox,
    Important,
    Starred,
    Sent,
    Drafts,
    Archive,
    All,
    Spam,
    Bin,
    Other,
}

fn get_order_index_for_folder_type(folder_type: FolderType) -> u32 {
    match folder_type {
        FolderType::Inbox => 1,
        FolderType::Important => 2,
        FolderType::Starred => 3,
        FolderType::Sent => 4,
        FolderType::Drafts => 5,
        FolderType::Archive => 6,
        FolderType::All => 7,
        FolderType::Spam => 8,
        FolderType::Bin => 9,
        FolderType::Other => 10,
    }
}

fn get_folder_type_from_folder(folder: &Folder) -> FolderType {
    match folder.folder_name.as_str() {
        "INBOX" => FolderType::Inbox,
        "Important" => FolderType::Important,
        "Sent" => FolderType::Sent,
        "Spam" => FolderType::Spam,
        "Junk" => FolderType::Spam,
        "Drafts" => FolderType::Drafts,
        "Archive" => FolderType::Archive,
        "All" => FolderType::All,
        "Starred" => FolderType::Starred,
        "Bin" => FolderType::Bin,
        "Trash" => FolderType::Bin,
        &_ => FolderType::Other,
    }
}

pub fn get_folder_presentation_name(folder: &Folder) -> &str {
    let folder_type = get_folder_type_from_folder(folder);
    match folder_type {
        FolderType::Inbox => "Inbox",
        FolderType::Important => "Important",
        FolderType::Starred => "Starred",
        FolderType::Sent => "Sent",
        FolderType::Drafts => "Drafts",
        FolderType::Archive => "Archive",
        FolderType::All => "All",
        FolderType::Spam => "Spam",
        FolderType::Bin => "Bin",
        FolderType::Other => &folder.folder_name,
    }
}

pub mod model {
    use super::*;
    use row_data::FolderRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct FolderListModel {
            pub store: Rc<RefCell<Option<Rc<services::Store>>>>,
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

                    data.set_folder(x.clone()); //@TODO should probably be an Rc to the item

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

        pub fn attach_store(self, store: Rc<services::Store>) {
            let self_ = imp::FolderListModel::from_obj(&self);

            self_.store.replace(Some(store));
        }

        pub fn load(&self) {
            let self_ = imp::FolderListModel::from_obj(self);

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

            let mut folders_list = self_
                .store
                .borrow()
                .as_ref()
                .unwrap()
                .get_folders(&self_.bare_identities.borrow()[0])
                .expect("Unable to get folders");

            folders_list.sort_unstable_by_key(|folder| {
                let folder_type = get_folder_type_from_folder(folder);
                get_order_index_for_folder_type(folder_type)
            });

            // @TODO add support for multiple identities
            self_.folders.replace(folders_list);

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
            let self_ = imp::FolderRowData::from_obj(self);
            self_.folder.replace(Some(folder));
        }
        pub fn get_folder(&self) -> Rc<RefCell<Option<models::Folder>>> {
            let self_ = imp::FolderRowData::from_obj(self);
            self_.folder.clone()
        }
    }
}
