use std::cell::RefCell;
use std::rc::Rc;

use gtk::glib;
use gtk::subclass::prelude::*;

use crate::models;

mod imp {

    use super::*;

    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    pub struct FoldersListItem {
        pub folder: Rc<RefCell<Option<models::Folder>>>,
    }

    // Basic declaration of our type for the GObject type system
    #[glib::object_subclass]
    impl ObjectSubclass for FoldersListItem {
        const NAME: &'static str = "FoldersListItem";
        type Type = super::FoldersListItem;
        type ParentType = gtk::Box;
        // Called once at the very beginning of instantiation of each instance and
        // creates the data structure that contains all our state
        fn new() -> Self {
            Self {
                folder: Default::default(),
            }
        }
    }
    impl ObjectImpl for FoldersListItem {}
    impl BoxImpl for FoldersListItem {}
    impl WidgetImpl for FoldersListItem {}
}

glib::wrapper! {
    pub struct FoldersListItem(ObjectSubclass<imp::FoldersListItem>) @extends gtk::Widget, gtk::Box;
}
impl FoldersListItem {
    pub fn new() -> FoldersListItem {
        glib::Object::new::<FoldersListItem>()
    }

    pub fn new_with_folder(folder: &models::Folder) -> FoldersListItem {
        let instance = Self::new();

        let self_ = imp::FoldersListItem::from_obj(&instance);
        //@TODO can we get rid of this clone?
        self_.folder.replace(Some(folder.clone()));

        instance
    }

    pub fn get_folder(&self) -> Rc<RefCell<Option<models::Folder>>> {
        let self_ = imp::FoldersListItem::from_obj(self);
        self_.folder.clone()
    }
}
