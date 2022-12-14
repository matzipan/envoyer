use gtk::{gdk, glib, graphene, gsk, pango};

use gtk::prelude::*;

use log::info;

use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::CString;
use std::hash::Hash;
use std::rc::Rc;
use std::sync::{Arc, Mutex};

use crate::bindings;
use crate::controllers::ApplicationMessage;
use crate::models;

pub mod dynamic_list_view;

pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    threads_list_box: gtk::ListBox,
    conversation_viewer_list_box: gtk::ListBox,
}

#[derive(Clone, Debug, Default)]
struct DynamicListViewStore<KeyType, ItemType> {
    map: HashMap<KeyType, ItemType>,
}

impl<KeyType, ItemType> DynamicListViewStore<KeyType, ItemType>
where
    KeyType: Eq + Hash,
{
    fn len(&self) -> usize {
        self.map.len()
    }

    fn insert(&mut self, item_position: KeyType, child: ItemType) -> Option<ItemType> {
        self.map.insert(item_position, child)
    }

    fn get(&self, key: &KeyType) -> Option<&ItemType> {
        self.map.get(key)
    }
}

pub mod folders_list_item {
    use super::*;

    use gtk::subclass::prelude::*;
    // Implementation sub-module of the GObject
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

    // The public part
    glib::wrapper! {
        pub struct FoldersListItem(ObjectSubclass<imp::FoldersListItem>) @extends gtk::Widget, gtk::Box;
    }
    impl FoldersListItem {
        pub fn new() -> FoldersListItem {
            glib::Object::new::<FoldersListItem>(&[])
        }

        pub fn new_with_folder(folder: &models::Folder) -> FoldersListItem {
            let instance = Self::new();

            let self_ = imp::FoldersListItem::from_instance(&instance);
            //@TODO can we get rid of this clone?
            self_.folder.replace(Some(folder.clone()));

            instance
        }

        pub fn get_folder(&self) -> Rc<RefCell<Option<models::Folder>>> {
            let self_ = imp::FoldersListItem::from_instance(self);
            self_.folder.clone()
        }
    }
}

pub mod folder_conversation_item {
    use super::*;

    use gtk::subclass::prelude::*;
    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct FolderConversationItem {
            pub conversation: Rc<RefCell<Option<models::MessageSummary>>>,
            pub item_index: RefCell<i32>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for FolderConversationItem {
            const NAME: &'static str = "FolderConversationItem";
            type Type = super::FolderConversationItem;
            type ParentType = gtk::ListBoxRow;
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
        impl ListBoxRowImpl for FolderConversationItem {}
        impl WidgetImpl for FolderConversationItem {}
    }

    // The public part
    glib::wrapper! {
        pub struct FolderConversationItem(ObjectSubclass<imp::FolderConversationItem>) @extends gtk::ListBoxRow, gtk::Widget, @implements gtk::Buildable, gtk::Actionable;
    }
    impl FolderConversationItem {
        pub fn new() -> FolderConversationItem {
            glib::Object::new::<FolderConversationItem>(&[])
        }

        pub fn new_with_item_index(item_index: i32) -> FolderConversationItem {
            let instance = Self::new();

            let self_ = imp::FolderConversationItem::from_instance(&instance);
            //@TODO can we get rid of this clone?
            self_.item_index.replace(item_index);

            instance
        }

        pub fn new_with_conversation(conversation: &models::MessageSummary) -> FolderConversationItem {
            let instance = Self::new();

            let self_ = imp::FolderConversationItem::from_instance(&instance);
            //@TODO can we get rid of this clone?
            self_.conversation.replace(Some(conversation.clone()));

            instance
        }

        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
            let self_ = imp::FolderConversationItem::from_instance(self);
            self_.conversation.clone()
        }

        pub fn get_item_index(&self) -> i32 {
            let self_ = imp::FolderConversationItem::from_instance(self);
            self_.item_index.borrow().to_owned()
        }
    }
}

pub mod message_view {
    use super::*;

    use gtk::subclass::prelude::*;
    // Implementation sub-module of the GObject
    mod imp {
        use crate::litehtml_callbacks;

        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct MessageView {
            pub litehtml_callbacks: Rc<RefCell<litehtml_callbacks::Callbacks>>,
            pub litehtml_context: Rc<RefCell<*mut core::ffi::c_void>>,
            pub loaded: Rc<RefCell<bool>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for MessageView {
            const NAME: &'static str = "MessageView";
            type Type = super::MessageView;
            type ParentType = gtk::Widget;
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    litehtml_callbacks: Rc::new(RefCell::new(litehtml_callbacks::Callbacks::new())),
                    litehtml_context: Rc::new(RefCell::new(0 as *mut core::ffi::c_void)),
                    loaded: Rc::new(RefCell::new(false)),
                }
            }
        }

        impl ObjectImpl for MessageView {
            fn constructed(&self) {
                self.parent_constructed();

                let obj = self.obj();
                obj.set_vexpand(true);
            }
        }

        impl WidgetImpl for MessageView {
            fn snapshot(&self, snapshot: &gtk::Snapshot) {
                if !*self.loaded.borrow() {
                    return;
                }

                let litehtml_context = self.litehtml_context.borrow_mut();

                let mut callbacks = self.litehtml_callbacks.borrow_mut();
                callbacks.clear_nodes();

                unsafe {
                    bindings::setup::draw(*litehtml_context);
                }

                let nodes = callbacks.nodes();

                let container_node = gsk::ContainerNode::new(&nodes);

                snapshot.append_node(&container_node);
            }

            fn request_mode(&self) -> gtk::SizeRequestMode {
                gtk::SizeRequestMode::HeightForWidth
            }

            fn measure(&self, orientation: gtk::Orientation, for_size: i32) -> (i32, i32, i32, i32) {
                let litehtml_context = self.litehtml_context.borrow_mut();

                match orientation {
                    gtk::Orientation::Horizontal => (0, 0, -1, -1),
                    gtk::Orientation::Vertical => {
                        let height = unsafe { bindings::setup::render(*litehtml_context, for_size * pango::SCALE) } / pango::SCALE;

                        (height, height, -1, -1)
                    }
                    _ => unimplemented!(),
                }
            }

            fn size_allocate(&self, width: i32, height: i32, baseline: i32) {
                let litehtml_context = self.litehtml_context.borrow_mut();

                unsafe { bindings::setup::render(*litehtml_context, width * pango::SCALE) };

                let obj = self.obj();

                obj.queue_draw();
            }
        }
    }

    // The public part
    glib::wrapper! {
        pub struct MessageView(ObjectSubclass<imp::MessageView>) @extends gtk::Widget, @implements gtk::Buildable, gtk::Actionable;
    }
    impl MessageView {
        pub fn new() -> MessageView {
            glib::Object::new::<MessageView>(&[])
        }

        pub fn load_content(&self, content: &String) {
            let self_ = imp::MessageView::from_instance(self);

            let master_stylesheet = include_str!("../ui/webview_stylesheet.css");
            let master_stylesheet = CString::new(master_stylesheet).expect("Could not build master stylesheet CString");

            let s = CString::new(&**content).expect("CString::new failed");

            let mut litehtml_context = self_.litehtml_context.borrow_mut();

            unsafe {
                *litehtml_context = bindings::setup::setup_litehtml(
                    master_stylesheet.as_ptr(),
                    s.as_ptr(),
                    RefCell::as_ptr(&self_.litehtml_callbacks) as *mut core::ffi::c_void,
                );
            }

            *self_.loaded.borrow_mut() = true;

            self.queue_resize();
        }
    }
}

pub mod conversation_message_item {
    use super::*;

    use gtk::subclass::prelude::*;
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
            glib::Object::new::<ConversationMessageItem>(&[])
        }

        pub fn new_with_message(message: &models::Message) -> ConversationMessageItem {
            let instance = Self::new();

            let self_ = imp::ConversationMessageItem::from_instance(&instance);
            //@TODO can we get rid of this clone?
            self_.message.replace(Some(message.clone()));

            instance
        }

        pub fn get_message(&self) -> Rc<RefCell<Option<models::Message>>> {
            let self_ = imp::ConversationMessageItem::from_instance(self);
            self_.message.clone()
        }
    }
}

impl Window {
    pub fn new(
        application: &gtk::Application,
        sender: glib::Sender<ApplicationMessage>,
        folders_list_model: &models::folders_list::model::FolderListModel,
        conversations_list_model: &models::folder_conversations_list::model::FolderModel,
        conversation_model: &models::conversation_messages_list::model::ConversationModel,
    ) -> Window {
        //@TODO set icon
        let gtk_window = gtk::ApplicationWindow::new(application);
        let header = gtk::HeaderBar::new();
        header.set_title_widget(Some(&gtk::Label::new(Some("Envoyer"))));
        gtk_window.set_titlebar(Some(&header));
        gtk_window.set_default_size(1600, 900);

        gtk::Window::set_default_icon_name("iconname");
        let my_str = include_str!("stylesheet.css");
        let provider = gtk::CssProvider::new();
        provider.load_from_data(my_str.as_bytes());
        gtk::StyleContext::add_provider_for_display(
            &gdk::Display::default().expect("Error initializing gtk css provider."),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        let factory = gtk::SignalListItemFactory::new();
        factory.connect_bind(move |_factory, list_item| {
            let item = list_item.item().unwrap();

            let folder_row_data = item
                .downcast_ref::<models::folders_list::row_data::FolderRowData>()
                .expect("Row data is of wrong type");

            let folder_rc = folder_row_data.get_folder();
            let folder_borrow = folder_rc.borrow();
            let folder = folder_borrow.as_ref().expect("Model contents invalid");

            let box_item = folders_list_item::FoldersListItem::new_with_folder(&folder);

            box_item.style_context().add_class("folders_list_item");

            let name_label = gtk::Label::new(None);

            name_label.set_text(&folder.folder_name);
            name_label.set_halign(gtk::Align::Start);

            box_item.append(&name_label);

            list_item.set_child(Some(&box_item));
        });

        let selection_model = gtk::NoSelection::new(Some(folders_list_model));
        let folders_list_view = gtk::ListView::new(Some(&selection_model), Some(&factory));
        folders_list_view.style_context().add_class("folders_sidebar");
        folders_list_view.set_single_click_activate(true);

        let folders_scroll_box = gtk::ScrolledWindow::new();
        folders_scroll_box.set_vexpand(true);
        folders_scroll_box.set_size_request(200, -1);
        folders_scroll_box.set_child(Some(&folders_list_view));

        let threads_list_box = gtk::ListBox::new();
        threads_list_box.set_activate_on_single_click(false);
        threads_list_box.set_selection_mode(gtk::SelectionMode::Multiple);

        let folder_conversations_scroll_box = gtk::ScrolledWindow::new();
        folder_conversations_scroll_box.set_vexpand(true);
        folder_conversations_scroll_box.set_size_request(200, -1);
        folder_conversations_scroll_box.set_child(Some(&threads_list_box));

        let conversation_viewer_list_box = gtk::ListBox::new();
        conversation_viewer_list_box.style_context().add_class("conversation_viewer");

        let conversation_viewer_scroll_box = gtk::ScrolledWindow::new();
        conversation_viewer_scroll_box.set_hexpand(true);
        conversation_viewer_scroll_box.set_hscrollbar_policy(gtk::PolicyType::Never);
        conversation_viewer_scroll_box.set_child(Some(&conversation_viewer_list_box));

        let spinner = gtk::Spinner::new();

        spinner.set_size_request(40, 40);
        spinner.set_halign(gtk::Align::Center);
        spinner.set_valign(gtk::Align::Center);

        let please_wait_label = gtk::Label::new(Some("Please wait"));
        please_wait_label.style_context().add_class("h1");
        please_wait_label.set_halign(gtk::Align::Start);

        let loading_label = gtk::Label::new(Some("Loading message contents."));
        loading_label.set_margin_bottom(40);

        let please_wait_loading_contents_grid = gtk::Grid::new();
        please_wait_loading_contents_grid.set_orientation(gtk::Orientation::Vertical);
        please_wait_loading_contents_grid.set_halign(gtk::Align::Center);
        please_wait_loading_contents_grid.set_valign(gtk::Align::Center);
        please_wait_loading_contents_grid
            .style_context()
            .add_class("please_wait_loading_contents_grid");
        please_wait_loading_contents_grid.attach(&please_wait_label, 0, 0, 1, 1);
        please_wait_loading_contents_grid.attach(&loading_label, 0, 1, 1, 1);
        please_wait_loading_contents_grid.attach(&spinner, 0, 2, 1, 1);

        let conversation_viewer_stack = gtk::Stack::new();
        conversation_viewer_stack.add_named(&conversation_viewer_scroll_box, Some("conversation-viewer"));
        conversation_viewer_stack.add_named(&please_wait_loading_contents_grid, Some("loading"));

        let main_grid = gtk::Grid::new();

        main_grid.set_orientation(gtk::Orientation::Horizontal);

        main_grid.attach(&folders_scroll_box, 0, 0, 1, 1);
        main_grid.attach(&folder_conversations_scroll_box, 1, 0, 1, 1);
        main_grid.attach(&conversation_viewer_stack, 2, 0, 1, 1);

        gtk_window.set_child(Some(&main_grid));

        let sender_clone = sender.clone();

        folders_list_view.connect_activate(move |list_view, position| {
            let model = list_view.model().unwrap();
            let item = model.item(position);

            if let Some(item) = item {
                let item = item
                    .downcast_ref::<models::folders_list::row_data::FolderRowData>()
                    .expect("List box row is of wrong type");

                let folder_rc = item.get_folder();
                let folder_borrow = folder_rc.borrow();
                let folder = folder_borrow.as_ref().expect("Model contents invalid");

                info!("Selected folder with name \"{}\"", folder.folder_name);

                sender_clone
                    .send(ApplicationMessage::ShowFolder { folder: folder.clone() })
                    .expect("Unable to send application message");
            } else {
                // application.unload_current_folder ();
            }
        });

        let sender_clone = sender.clone();

        threads_list_box.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                let row = row
                    .downcast_ref::<folder_conversation_item::FolderConversationItem>()
                    .expect("List box row is of wrong type");

                let conversation = row.get_conversation();

                let message = conversation.borrow().as_ref().expect("Model configuration invalid").clone();

                info!("Selected conversation with subject \"{}\"", message.subject);

                sender_clone
                    .send(ApplicationMessage::ShowConversation { conversation: message })
                    .expect("Unable to send application message");
            } else {
                //         application.unload_current_conversation_thread ();
            }
        });

        threads_list_box.bind_model(Some(conversations_list_model), |item| {
            let item = item
                .downcast_ref::<models::folder_conversations_list::row_data::ConversationRowData>()
                .expect("Row data is of wrong type");
            let conversation_rc = item.get_conversation();
            let conversation_borrow = conversation_rc.borrow();
            let conversation = conversation_borrow.as_ref().expect("Model contents invalid");

            let box_row = folder_conversation_item::FolderConversationItem::new_with_conversation(&conversation);
            box_row.style_context().add_class("folder_conversation_item");

            let subject_label = gtk::Label::new(None);
            subject_label.set_hexpand(true);
            subject_label.set_halign(gtk::Align::Start);
            subject_label.set_ellipsize(pango::EllipsizeMode::End);
            subject_label.style_context().add_class("subject");
            subject_label.set_xalign(0.0);

            let attachment_image = gtk::Image::from_icon_name(&"mail-attachment-symbolic");
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
            let star_image = gtk::Button::from_icon_name(&"starred");
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
            outer_grid.set_margin_top(4);
            outer_grid.set_margin_bottom(4);
            outer_grid.set_margin_start(8);
            outer_grid.set_margin_end(8);

            outer_grid.attach(&top_grid, 0, 0, 1, 1);
            outer_grid.attach(&bottom_grid, 0, 1, 1, 1);

            box_row.set_child(Some(&outer_grid));

            // Load data
            // @TODO Currently this is done in a very naive way, to be detailed later
            addresses_label.set_text(&conversation.from);
            subject_label.set_text(&conversation.subject);

            //@TODO implement an autoupdating timestamp
            datetime_received_label.set_text(&conversation.get_relative_time_ago());

            datetime_received_label.set_tooltip_text(Some(&conversation.time_received.to_string()));

            attachment_image.hide();
            star_image.hide();

            box_row.upcast::<gtk::Widget>()

            // set_swipe_icon_name ("envoyer-delete-symbolic");
        });

        conversation_model.connect_is_loading(move |args| {
            let is_loading = args[1].get::<bool>().expect("The is_loading value needs to be of type `bool`.");

            if is_loading {
                conversation_viewer_stack.set_visible_child_name("loading");
                spinner.start();
            } else {
                conversation_viewer_stack.set_visible_child_name("conversation-viewer");
                spinner.stop();
            }

            None
        });

        conversation_viewer_list_box.bind_model(Some(conversation_model), |item| {
            let item = item
                .downcast_ref::<models::conversation_messages_list::row_data::MessageRowData>()
                .expect("Row data is of wrong type");
            let message_rc = item.get_message();
            let message_borrow = message_rc.borrow();
            let message = message_borrow.as_ref().expect("Model contents invalid");

            let box_row = conversation_message_item::ConversationMessageItem::new_with_message(&message);
            box_row.style_context().add_class("conversation_message_item");
            box_row.set_selectable(false);

            let subject_label = gtk::Label::new(None);
            subject_label.set_ellipsize(gtk::pango::EllipsizeMode::End);
            subject_label.set_halign(gtk::Align::Start);
            subject_label.style_context().add_class("subject");
            subject_label.set_xalign(0.0);

            let from_addresses_list = gtk::Label::new(None);
            from_addresses_list.set_ellipsize(gtk::pango::EllipsizeMode::End);
            from_addresses_list.set_halign(gtk::Align::Start);
            from_addresses_list.style_context().add_class("from");
            from_addresses_list.style_context().add_class("addresses");

            let to_addresses_label = gtk::Label::new(Some(&"to"));
            to_addresses_label.style_context().add_class("addresses_label");
            let to_addresses_list = gtk::Label::new(None);
            to_addresses_list.set_ellipsize(gtk::pango::EllipsizeMode::End);
            to_addresses_list.set_hexpand(true);
            to_addresses_list.set_halign(gtk::Align::Start);
            let to_addresses_grid = gtk::Grid::new();
            to_addresses_grid.style_context().add_class("to");
            to_addresses_grid.style_context().add_class("addresses");
            to_addresses_grid.attach(&to_addresses_label, 0, 0, 1, 1);
            to_addresses_grid.attach(&to_addresses_list, 1, 0, 1, 1);

            let cc_addresses_label = gtk::Label::new(Some(&"cc"));
            cc_addresses_label.style_context().add_class("addresses_label");
            let cc_addresses_list = gtk::Label::new(None);
            cc_addresses_list.set_ellipsize(gtk::pango::EllipsizeMode::End);
            cc_addresses_list.set_hexpand(true);
            cc_addresses_list.set_halign(gtk::Align::Start);
            let cc_addresses_grid = gtk::Grid::new();
            cc_addresses_grid.style_context().add_class("cc");
            cc_addresses_grid.style_context().add_class("addresses");
            cc_addresses_grid.attach(&cc_addresses_label, 0, 0, 1, 1);
            cc_addresses_grid.attach(&cc_addresses_list, 1, 0, 1, 1);

            let bcc_addresses_label = gtk::Label::new(Some(&"bcc"));
            bcc_addresses_label.style_context().add_class("addresses_label");
            let bcc_addresses_list = gtk::Label::new(None);
            bcc_addresses_list.set_ellipsize(gtk::pango::EllipsizeMode::End);
            bcc_addresses_list.set_hexpand(true);
            bcc_addresses_list.set_halign(gtk::Align::Start);
            let bcc_addresses_grid = gtk::Grid::new();
            bcc_addresses_grid.style_context().add_class("bcc");
            bcc_addresses_grid.style_context().add_class("addresses");
            bcc_addresses_grid.attach(&bcc_addresses_label, 0, 0, 1, 1);
            bcc_addresses_grid.attach(&bcc_addresses_list, 1, 0, 1, 1);

            let header_summary_fields = gtk::Grid::new();
            header_summary_fields.set_row_spacing(1);
            header_summary_fields.set_hexpand(true);
            header_summary_fields.set_valign(gtk::Align::Start);
            header_summary_fields.set_orientation(gtk::Orientation::Vertical);
            header_summary_fields.style_context().add_class("header_summary_fields");
            header_summary_fields.attach(&subject_label, 0, 0, 1, 1);
            header_summary_fields.attach(&from_addresses_list, 0, 1, 1, 1);
            header_summary_fields.attach(&to_addresses_grid, 0, 2, 1, 1);
            header_summary_fields.attach(&cc_addresses_grid, 0, 3, 1, 1);
            header_summary_fields.attach(&bcc_addresses_grid, 0, 4, 1, 1);

            let datetime_received_label = gtk::Label::new(None);
            datetime_received_label.style_context().add_class("received");
            datetime_received_label.set_valign(gtk::Align::Start);

            let attachment_indicator = gtk::Image::from_icon_name(&"mail-attachment-symbolic");
            attachment_indicator.style_context().add_class("attachment_indicator");
            attachment_indicator.set_valign(gtk::Align::Start);
            attachment_indicator.set_sensitive(false);
            attachment_indicator.set_tooltip_text(Some(&"This message contains one or more attachments"));

            let message_header = gtk::Grid::new();
            message_header.set_can_focus(false);
            message_header.set_orientation(gtk::Orientation::Horizontal);
            message_header.attach(&header_summary_fields, 0, 0, 1, 1);
            message_header.attach(&attachment_indicator, 1, 0, 1, 1);
            message_header.attach(&datetime_received_label, 2, 0, 1, 1);

            let message_view = gtk::TextView::new();

            let buffer = message_view.buffer();

            let attachments_list = gtk::Grid::new();
            attachments_list.set_orientation(gtk::Orientation::Vertical);

            let view = message_view::MessageView::new();

            let grid = gtk::Grid::new();
            grid.set_orientation(gtk::Orientation::Vertical);
            grid.attach(&message_header, 0, 0, 1, 1);
            grid.attach(&attachments_list, 0, 1, 1, 1);
            grid.attach(&view, 0, 2, 1, 1);

            box_row.set_child(Some(&grid));

            if message.subject.trim().is_empty() {
                subject_label.hide();
            } else {
                subject_label.set_text(&message.subject);
            }

            if message.to.trim().is_empty() {
                to_addresses_grid.hide();
            } else {
                to_addresses_list.set_text(&message.to);
            }

            if message.from.trim().is_empty() {
                from_addresses_list.hide();
            } else {
                from_addresses_list.set_text(&message.from);
            }

            if message.cc.trim().is_empty() {
                cc_addresses_grid.hide();
            } else {
                cc_addresses_list.set_text(&message.cc);
            }

            if message.bcc.trim().is_empty() {
                bcc_addresses_grid.hide();
            } else {
                bcc_addresses_list.set_text(&message.bcc);
            }

            attachment_indicator.hide();

            //@TODO implement an autoupdating timestamp
            datetime_received_label.set_text(&message.get_relative_time_ago());
            //@TODO
            datetime_received_label.set_tooltip_text(Some(&message.time_received.to_string()));

            view.load_content(message.content.as_ref().unwrap_or(&"".to_string()));

            box_row.upcast::<gtk::Widget>()
        });

        Self {
            gtk_window,
            threads_list_box,
            conversation_viewer_list_box,
        }
    }

    pub fn show(&self) {
        self.gtk_window.show();
        self.gtk_window.present_with_time((glib::monotonic_time() / 1000) as u32);
    }

    // public new void grab_focus () {
    //     listbox.grab_focus ();
    // }

    //     public void show_app () {
    //         show ();
    //       present ();

    //       folder_conversations_list.grab_focus ();
    //   }

    // let (roots, threads, envelopes) =
    // self.identities.lock().expect("Unable to acquire identities lock")[0]
    //     .clone()
    //     .fetch_threads();

    // let iter = roots.into_iter();
    // for thread in iter {
    //     let thread_node =
    // &threads.thread_nodes()[&threads.thread_ref(thread).root()];
    //     let root_envelope_hash = if let Some(h) =
    // thread_node.message().or_else(|| {         if
    // thread_node.children().is_empty() {             return None;
    //         }
    //         let mut iter_ptr = thread_node.children()[0];
    //         while threads.thread_nodes()[&iter_ptr].message().is_none() {
    //             if
    // threads.thread_nodes()[&iter_ptr].children().is_empty() {
    //                 return None;
    //             }
    //             iter_ptr =
    // threads.thread_nodes()[&iter_ptr].children()[0];         }
    //         threads.thread_nodes()[&iter_ptr].message()
    //     }) {
    //         h
    //     } else {
    //         continue;
    //     };

    //     let row_data = FolderConversationRowData::new(&"Subject
    // placeholder");     unsafe {
    //         (*row_data.as_ptr()).get_impl().subject.replace(Some(
    //
    // threads.thread_nodes()[&threads.thread_ref(thread).root()]
    //                 .message()
    //                 .as_ref()
    //                 .map(|m|
    // envelopes.read().unwrap()[m].subject().to_string())
    //                 .unwrap_or_else(|| "None".to_string()),
    //         ));
    //     }

    //     self.threads_model.append(&row_data)
}
