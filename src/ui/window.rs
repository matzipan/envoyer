use gtk::{gdk, glib, pango};

use gtk::prelude::*;

use log::info;

use std::sync::{Arc, Mutex};

use crate::models;

use std::cell::RefCell;
use std::rc::Rc;

use crate::controllers::ApplicationMessage;

pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    threads_list_box: gtk::ListBox,
    conversation_viewer_list_box: gtk::ListBox,
    identities: Arc<Mutex<Vec<models::Identity>>>,
    folder_model: models::folder_conversations_list::model::FolderModel,
    conversation_model: models::conversation_messages_list::model::ConversationModel,
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
            pub conversation: Rc<RefCell<Option<models::Message>>>,
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
            glib::Object::new(&[]).expect("Failed to create row data")
        }

        pub fn new_with_conversation(conversation: &models::Message) -> FolderConversationItem {
            let instance = Self::new();

            let self_ = imp::FolderConversationItem::from_instance(&instance);
            //@TODO can we get rid of this clone?
            self_.conversation.replace(Some(conversation.clone()));

            instance
        }

        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::Message>>> {
            let self_ = imp::FolderConversationItem::from_instance(self);
            self_.conversation.clone()
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
            glib::Object::new(&[]).expect("Failed to create row data")
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
        identities: Arc<Mutex<Vec<models::Identity>>>,
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

        let threads_list_box = gtk::ListBox::new();
        threads_list_box.set_activate_on_single_click(false);
        threads_list_box.set_selection_mode(gtk::SelectionMode::Multiple);

        let folder_conversations_scroll_box = gtk::ScrolledWindow::new();
        folder_conversations_scroll_box.set_vexpand(true);
        folder_conversations_scroll_box.set_size_request(200, -1);
        folder_conversations_scroll_box.set_child(Some(&threads_list_box));

        let conversation_viewer_list_box = gtk::ListBox::new();
        conversation_viewer_list_box.set_can_target(false);

        let conversation_viewer_scroll_box = gtk::ScrolledWindow::new();
        conversation_viewer_scroll_box.set_hexpand(true);
        conversation_viewer_scroll_box.set_hscrollbar_policy(gtk::PolicyType::Never);
        conversation_viewer_scroll_box.set_child(Some(&conversation_viewer_list_box));

        let main_grid = gtk::Grid::new();

        main_grid.set_orientation(gtk::Orientation::Horizontal);
        main_grid.attach(&folder_conversations_scroll_box, 0, 0, 1, 1);
        main_grid.attach(&conversation_viewer_scroll_box, 1, 0, 1, 1);

        gtk_window.set_child(Some(&main_grid));

        let folder_model = models::folder_conversations_list::model::FolderModel::new();
        let conversation_model = models::conversation_messages_list::model::ConversationModel::new();

        let sender_clone = sender.clone();

        threads_list_box.connect_row_selected(move |_, row| {
            if let Some(row) = row {
                let row = row
                    .downcast_ref::<folder_conversation_item::FolderConversationItem>()
                    .expect("List box row is of wrong type");

                let conversation = row.get_conversation();

                let message = conversation.borrow().as_ref().expect("Model configuration invalid").clone();

                info!("Opening conversation with subject \"{}\"", message.subject);

                sender_clone
                    .send(ApplicationMessage::ShowConversation { conversation: message })
                    .expect("Unable to send application message");
            } else {
                //         application.unload_current_conversation_thread ();
            }
        });

        threads_list_box.bind_model(Some(&folder_model), |item| {
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

            let attachment_image = gtk::Image::from_icon_name(Some("mail-attachment-symbolic"));
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
            let star_image = gtk::Button::from_icon_name(Some("starred"));
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

        conversation_viewer_list_box.bind_model(Some(&conversation_model), |item| {
            let item = item
                .downcast_ref::<models::conversation_messages_list::row_data::MessageRowData>()
                .expect("Row data is of wrong type");
            let message_rc = item.get_message();
            let message_borrow = message_rc.borrow();
            let message = message_borrow.as_ref().expect("Model contents invalid");

            let box_row = conversation_message_item::ConversationMessageItem::new_with_message(&message);

            let subject_label = gtk::Label::new(None);
            subject_label.set_text(&message.subject);

            box_row.set_child(Some(&subject_label));

            box_row.upcast::<gtk::Widget>()
        });

        Self {
            gtk_window,
            threads_list_box,
            conversation_viewer_list_box,
            identities,
            folder_model,
            conversation_model,
        }
    }

    pub fn show(&self) {
        self.gtk_window.show();
        self.gtk_window.present_with_time((glib::monotonic_time() / 1000) as u32);
    }

    pub fn show_conversations(&self, conversations: Vec<models::Message>) {
        for conversation in conversations {
            let data = models::folder_conversations_list::row_data::ConversationRowData::new();

            data.set_conversation(conversation);

            self.folder_model.append(&data);
        }

        // public new void grab_focus () {
        //     listbox.grab_focus ();
        // }
        // public void load_folder_handler (IFolder folder) {
        //     current_folder = folder;

        //     listbox.bind_model (folder.conversations_list_model,
        // walk_model_items);
        //     grab_focus ();
        //     // @TODO listbox.select_row (item);
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

    pub fn show_conversation(&self, conversation: models::Message) {
        let data = models::conversation_messages_list::row_data::MessageRowData::new();

        data.set_message(conversation);

        self.conversation_model.remove_all();

        self.conversation_model.append(&data);
    }
}
