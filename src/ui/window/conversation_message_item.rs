use super::*;

// Implementation sub-module of the GObject
mod imp {
    use super::*;

    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    pub struct ConversationMessageItem {
        pub message: Rc<RefCell<Option<models::Message>>>,
    }

    // Basic declaration of our type for the GObject type system
    #[glib::object_subclass]
    impl ObjectSubclass for ConversationMessageItem {
        const NAME: &'static str = "ConversationMessageItem";
        type Type = super::ConversationMessageItem;
        type ParentType = gtk::ListBoxRow;
        // Called once at the very beginning of instantiation of each instance and
        // creates the data structure that contains all our state
        fn new() -> Self {
            Self {
                message: Default::default(),
            }
        }
    }
    impl ObjectImpl for ConversationMessageItem {}
    impl ListBoxRowImpl for ConversationMessageItem {}
    impl WidgetImpl for ConversationMessageItem {}
}

// The public part
glib::wrapper! {
    pub struct ConversationMessageItem(ObjectSubclass<imp::ConversationMessageItem>) @extends gtk::ListBoxRow, gtk::Widget, @implements gtk::Buildable, gtk::Actionable;
}
impl ConversationMessageItem {
    pub fn new() -> ConversationMessageItem {
        glib::Object::new::<ConversationMessageItem>()
    }

    pub fn new_with_message(message: &models::Message) -> ConversationMessageItem {
        let instance = Self::new();

        let self_ = imp::ConversationMessageItem::from_obj(&instance);
        //@TODO can we get rid of this clone?
        self_.message.replace(Some(message.clone()));

        instance
    }

    pub fn get_message(&self) -> Rc<RefCell<Option<models::Message>>> {
        let self_ = imp::ConversationMessageItem::from_obj(self);
        self_.message.clone()
    }
}
