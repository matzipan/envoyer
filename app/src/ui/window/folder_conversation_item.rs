use super::*;

// Implementation sub-module of the GObject
mod imp {
    use gtk::glib::WeakRef;

    use super::*;

    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    pub struct FolderConversationItem {
        conversation: Rc<RefCell<Option<models::MessageSummary>>>,
        pub item_index: RefCell<u32>,
        addresses_label: Rc<WeakRef<gtk::Label>>,
        subject_label: Rc<WeakRef<gtk::Label>>,
        datetime_received_label: Rc<WeakRef<gtk::Label>>,
        star_image: Rc<WeakRef<gtk::Button>>,
        attachment_image: Rc<WeakRef<gtk::Image>>,
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
                addresses_label: Default::default(),
                subject_label: Default::default(),
                datetime_received_label: Default::default(),
                star_image: Default::default(),
                attachment_image: Default::default(),
            }
        }
    }
    impl ObjectImpl for FolderConversationItem {
        fn constructed(&self) {
            self.parent_constructed();

            let obj = self.obj();

            obj.style_context().add_class("folder_conversation_item");

            let subject_label = gtk::Label::new(None);
            subject_label.set_hexpand(true);
            subject_label.set_halign(gtk::Align::Start);
            subject_label.set_ellipsize(pango::EllipsizeMode::End);
            subject_label.style_context().add_class("subject");
            subject_label.set_xalign(0.0);

            let attachment_image = gtk::Image::from_icon_name("mail-attachment-symbolic");
            attachment_image.set_sensitive(false);
            attachment_image.set_tooltip_text(Some("This thread contains one or more attachments"));

            let top_grid = gtk::Grid::new();
            top_grid.set_orientation(gtk::Orientation::Horizontal);
            top_grid.set_column_spacing(3);

            // unseen_dot = new Envoyer.Widgets.Main.UnseenDot ();
            // unseen_dot.no_show_all = true;
            // top_grid.add (unseen_dot);
            top_grid.attach(&subject_label, 0, 0, 1, 1);
            top_grid.attach(&attachment_image, 1, 0, 1, 1);

            //@TODO make smaller star_image.
            let star_image = gtk::Button::from_icon_name("starred");
            star_image.style_context().add_class("star");
            star_image.set_sensitive(true);
            star_image.set_tooltip_text(Some("Mark this thread as starred"));

            let addresses_label = gtk::Label::new(None);
            addresses_label.set_hexpand(true);
            addresses_label.set_halign(gtk::Align::Start);
            addresses_label.set_ellipsize(pango::EllipsizeMode::End);
            addresses_label.style_context().add_class("addresses");

            let datetime_received_label = gtk::Label::new(None);
            datetime_received_label.style_context().add_class("received");

            let bottom_grid = gtk::Grid::new();
            bottom_grid.set_orientation(gtk::Orientation::Horizontal);
            bottom_grid.set_column_spacing(3);
            bottom_grid.attach(&addresses_label, 0, 0, 1, 1);
            bottom_grid.attach(&datetime_received_label, 1, 0, 1, 1);
            bottom_grid.attach(&star_image, 2, 0, 1, 1);

            let outer_grid = gtk::Grid::new();
            outer_grid.set_orientation(gtk::Orientation::Vertical);
            outer_grid.set_row_spacing(3);
            outer_grid.set_margin_top(9);
            outer_grid.set_margin_bottom(0);
            outer_grid.set_margin_start(8);
            outer_grid.set_margin_end(8);

            outer_grid.attach(&top_grid, 0, 0, 1, 1);
            outer_grid.attach(&bottom_grid, 0, 1, 1, 1);

            obj.append(&outer_grid);

            self.addresses_label.set(Some(&addresses_label));
            self.subject_label.set(Some(&subject_label));
            self.datetime_received_label.set(Some(&datetime_received_label));
            self.attachment_image.set(Some(&attachment_image));
            self.star_image.set(Some(&star_image));

            // // set_swipe_icon_name ("envoyer-delete-symbolic");
        }
    }

    impl BoxImpl for FolderConversationItem {}
    impl WidgetImpl for FolderConversationItem {}

    impl FolderConversationItem {
        pub fn set_conversation(&self, conversation: models::MessageSummary) {
            // Load data
            // @TODO Currently this is done in a very naive way, to be detailed later
            if let Some(addresses_label) = self.addresses_label.upgrade() {
                addresses_label.set_text(&conversation.from);
            }

            if let Some(subject_label) = self.subject_label.upgrade() {
                subject_label.set_text(&conversation.subject);
            }

            //@TODO implement an autoupdating timestamp
            if let Some(datetime_received_label) = self.datetime_received_label.upgrade() {
                datetime_received_label.set_text(&conversation.get_relative_time_ago());
                datetime_received_label.set_tooltip_text(Some(&conversation.time_received.to_string()));
            }

            if let Some(attachment_image) = self.attachment_image.upgrade() {
                attachment_image.hide();
            }

            if let Some(star_image) = self.star_image.upgrade() {
                star_image.hide();
            }

            self.conversation.replace(Some(conversation));
        }

        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
            self.conversation.clone()
        }

        pub fn set_activate_function(&self, activate_function: impl Fn() + 'static) {
            let obj = self.obj();

            let gesture = gtk::GestureClick::new();
            gesture.connect_released(move |gesture, _, _, _| {
                gesture.set_state(gtk::EventSequenceState::Claimed);
                activate_function();
            });
            obj.add_controller(gesture);
        }
    }
}

// The public part
glib::wrapper! {
    pub struct FolderConversationItem(ObjectSubclass<imp::FolderConversationItem>) @extends gtk::Box, gtk::Widget, @implements gtk::Buildable, gtk::Actionable;
}
impl FolderConversationItem {
    pub fn new() -> FolderConversationItem {
        glib::Object::new::<FolderConversationItem>()
    }

    pub fn new_with_item_index_and_conversation(item_index: u32, conversation: &models::MessageSummary) -> FolderConversationItem {
        let instance = Self::new();

        let self_ = imp::FolderConversationItem::from_obj(&instance);

        self_.item_index.replace(item_index);

        //@TODO can we get rid of this clone?
        self_.set_conversation(conversation.clone());

        instance
    }

    pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
        let self_ = imp::FolderConversationItem::from_obj(self);
        self_.get_conversation()
    }

    pub fn get_item_index(&self) -> u32 {
        let self_ = imp::FolderConversationItem::from_obj(self);
        self_.item_index.borrow().to_owned()
    }

    pub fn connect_activate(&self, activate_function: impl Fn() + 'static) {
        let self_ = imp::FolderConversationItem::from_obj(self);
        self_.set_activate_function(activate_function);
    }
}
