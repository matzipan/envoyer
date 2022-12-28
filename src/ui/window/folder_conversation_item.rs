use super::*;

use gtk::subclass::prelude::*;
// Implementation sub-module of the GObject
mod imp {
    use super::*;

    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    pub struct FolderConversationItem {
        pub conversation: Rc<RefCell<Option<models::MessageSummary>>>,
        pub item_index: RefCell<u32>,
    }

    // Basic declaration of our type for the GObject type system
    #[glib::object_subclass]
    impl ObjectSubclass for FolderConversationItem {
        const NAME: &'static str = "FolderConversationItem";
        type Type = super::FolderConversationItem;
        type ParentType = gtk::Box;
        // Called once at the very beginning of instantiation of each instance and
        // creates the data structure that contains all our state
        fn new() -> Self {
            Self {
                conversation: Default::default(),
                item_index: RefCell::new(0),
            }
        }
    }
    impl ObjectImpl for FolderConversationItem {}
    impl BoxImpl for FolderConversationItem {}
    impl WidgetImpl for FolderConversationItem {}
}

// The public part
glib::wrapper! {
    pub struct FolderConversationItem(ObjectSubclass<imp::FolderConversationItem>) @extends gtk::Box, gtk::Widget, @implements gtk::Buildable, gtk::Actionable;
}
impl FolderConversationItem {
    pub fn new() -> FolderConversationItem {
        glib::Object::new::<FolderConversationItem>(&[])
    }

    pub fn new_with_item_index_and_conversation(item_index: u32, conversation: &models::MessageSummary) -> FolderConversationItem {
        let instance = Self::new();

        let self_ = imp::FolderConversationItem::from_instance(&instance);

        //@TODO can we get rid of this clone?
        self_.conversation.replace(Some(conversation.clone()));
        self_.item_index.replace(item_index);

        instance
    }

    pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
        let self_ = imp::FolderConversationItem::from_instance(self);
        self_.conversation.clone()
    }

    pub fn get_item_index(&self) -> u32 {
        let self_ = imp::FolderConversationItem::from_instance(self);
        self_.item_index.borrow().to_owned()
    }
}
