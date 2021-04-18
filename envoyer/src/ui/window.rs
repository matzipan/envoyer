use gtk::{gdk, glib, pango};

use gtk::prelude::*;

use log::info;

use std::sync::{Arc, Mutex};

use crate::models;

use std::cell::RefCell;
use std::rc::Rc;

pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    threads_list_box: gtk::ListBox,
    identities: Arc<Mutex<Vec<models::Identity>>>,
    model: models::folder_conversations_list::model::Model,
}

pub mod folder_conversation_item {
    use super::*;

    use glib::subclass;
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
                Self { conversation: Default::default() }
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

impl Window {
    pub fn new(application: &gtk::Application, identities: Arc<Mutex<Vec<models::Identity>>>) -> Window {
        //@TODO set icon
        let gtk_window = gtk::ApplicationWindow::new(application);
        let header = gtk::HeaderBar::new();
        header.set_title(Some("Envoyer"));
        header.set_show_close_button(true);
        gtk_window.set_titlebar(Some(&header));
        gtk_window.set_title("Envoyer");
        gtk_window.resize(1600, 900);

        gtk::Window::set_default_icon_name("iconname");
        let my_str = include_str!("stylesheet.css");
        let provider = gtk::CssProvider::new();
        provider.load_from_data(my_str.as_bytes()).expect("Failed to load CSS");
        gtk::StyleContext::add_provider_for_screen(
            &gdk::Screen::get_default().expect("Error initializing gtk css provider."),
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );

        let threads_list_box = gtk::ListBox::new();
        threads_list_box.set_activate_on_single_click(false);
        threads_list_box.set_selection_mode(gtk::SelectionMode::Multiple);

        let folder_conversations_scroll_box = gtk::ScrolledWindow::new(gtk::NONE_ADJUSTMENT, gtk::NONE_ADJUSTMENT);
        folder_conversations_scroll_box.set_vexpand(true);
        folder_conversations_scroll_box.set_size_request(200, -1);
        folder_conversations_scroll_box.add(&threads_list_box);

        let conversation_viewer_list_box = gtk::ListBox::new();

        let conversation_viewer_scroll_box = gtk::ScrolledWindow::new(gtk::NONE_ADJUSTMENT, gtk::NONE_ADJUSTMENT);
        conversation_viewer_scroll_box.set_hexpand(true);
        conversation_viewer_scroll_box.add(&conversation_viewer_list_box);
        conversation_viewer_scroll_box.set_property_hscrollbar_policy(gtk::PolicyType::Never);

        let main_grid = gtk::Grid::new();

        main_grid.set_orientation(gtk::Orientation::Horizontal);
        main_grid.add(&folder_conversations_scroll_box);
        main_grid.add(&conversation_viewer_scroll_box);

        gtk_window.add(&main_grid);

        let model = models::folder_conversations_list::model::Model::new();

        threads_list_box.connect_row_selected(|_, row| {
            if let Some(row) = row {
                let row = row
                    .downcast_ref::<folder_conversation_item::FolderConversationItem>()
                    .expect("List box row is of wrong type");


                let conversation  = row.get_conversation();

                info!("{}", conversation.borrow().as_ref().expect("Model configuration invalid").subject);
                    
                //         assert(row is FolderConversationItem);
                //         application.load_conversation_thread (((FolderConversationItem)
                // row).thread);     }
                //@TODO custom type is needed so we can get the  conversation instead of just getting the index
                // info!("{}", row.unwrap().get_index())
            } else {
                //         application.unload_current_conversation_thread ();   
            }
        });

        threads_list_box.bind_model(Some(&model), |item| {
            let item = item
                .downcast_ref::<models::folder_conversations_list::row_data::ConversationRowData>()
                .expect("Row data is of wrong type");
            
            let conversation_rc = item.get_conversation();
            let conversation_borrow = conversation_rc.borrow();
            let conversation = conversation_borrow.as_ref().expect("Model contents invalid");

            let box_row = folder_conversation_item::FolderConversationItem::new_with_conversation(&conversation);
            box_row.get_style_context().add_class("folder_conversation_item");

            let subject_label = gtk::Label::new(None);
            subject_label.set_hexpand(true);
            subject_label.set_halign(gtk::Align::Start);
            subject_label.set_ellipsize(pango::EllipsizeMode::End);
            subject_label.get_style_context().add_class("subject");
            subject_label.set_xalign(0.0);

            let attachment_image = gtk::Image::from_icon_name(Some("mail-attachment-symbolic"), gtk::IconSize::Menu);
            attachment_image.set_sensitive(false);
            attachment_image.set_tooltip_text(Some("This thread contains one or more attachments"));

            let top_grid = gtk::Grid::new();
            top_grid.set_orientation(gtk::Orientation::Horizontal);
            top_grid.set_column_spacing(3);

            // unseen_dot = new Envoyer.Widgets.Main.UnseenDot ();
            // unseen_dot.no_show_all = true;
            // top_grid.add (unseen_dot);
            top_grid.add(&subject_label);
            top_grid.add(&attachment_image);

            //@TODO make smaller star_image.
            let star_image = gtk::Button::from_icon_name(Some("starred"), gtk::IconSize::Menu);
            star_image.get_style_context().add_class("starred");
            star_image.set_sensitive(true);
            star_image.set_tooltip_text(Some("Mark this thread as starred"));

            let addresses_label = gtk::Label::new(None);
            addresses_label.set_hexpand(true);
            addresses_label.set_halign(gtk::Align::Start);
            addresses_label.set_ellipsize(pango::EllipsizeMode::End);
            addresses_label.get_style_context().add_class("addresses");
            addresses_label.get_style_context().add_class(&gtk::STYLE_CLASS_DIM_LABEL);

            let datetime_received_label = gtk::Label::new(None);

            let bottom_grid = gtk::Grid::new();
            bottom_grid.set_orientation(gtk::Orientation::Horizontal);
            bottom_grid.set_column_spacing(3);
            bottom_grid.add(&addresses_label);
            bottom_grid.add(&datetime_received_label);
            bottom_grid.add(&star_image);

            let outer_grid = gtk::Grid::new();
            outer_grid.set_orientation(gtk::Orientation::Vertical);
            outer_grid.set_row_spacing(3);
            outer_grid.set_margin_top(4);
            outer_grid.set_margin_bottom(4);
            outer_grid.set_margin_start(8);
            outer_grid.set_margin_end(8);

            outer_grid.add(&top_grid);
            outer_grid.add(&bottom_grid);

            box_row.add(&outer_grid);

            // Load data
            // @TODO Currently this is done in a very naive way, to be detailed later
            addresses_label.set_text(&conversation.from);
            subject_label.set_text(&conversation.subject);

            //@TODO implement an autoupdating timestamp
            datetime_received_label.set_text(&conversation.get_relative_time_ago());

            datetime_received_label.set_tooltip_text(Some(&conversation.time_received.to_string()));

            attachment_image.set_no_show_all(true);
            attachment_image.hide();
            star_image.set_no_show_all(true);
            star_image.hide();

            // box_row.show_all();

            box_row.upcast::<gtk::Widget>()

            // set_swipe_icon_name ("envoyer-delete-symbolic");
        });

        Self {
            gtk_window,
            threads_list_box,
            identities,
            model,
        }
    }

    pub fn show(&self) {
        self.gtk_window.show_all();
        self.gtk_window.present();
    }

    pub fn show_conversations(&self, conversations: Vec<models::Message>) {
        for conversation in conversations {
            let data = models::folder_conversations_list::row_data::ConversationRowData::new();

            data.set_conversation(conversation);

            self.model.append(&data);
        }
        // let (roots, threads, envelopes) = self.identities.lock().expect("Unable to acquire identities lock")[0]
        //     .clone()
        //     .fetch_threads();

        // let iter = roots.into_iter();
        // for thread in iter {
        //     let thread_node = &threads.thread_nodes()[&threads.thread_ref(thread).root()];
        //     let root_envelope_hash = if let Some(h) = thread_node.message().or_else(|| {
        //         if thread_node.children().is_empty() {
        //             return None;
        //         }
        //         let mut iter_ptr = thread_node.children()[0];
        //         while threads.thread_nodes()[&iter_ptr].message().is_none() {
        //             if threads.thread_nodes()[&iter_ptr].children().is_empty() {
        //                 return None;
        //             }
        //             iter_ptr = threads.thread_nodes()[&iter_ptr].children()[0];
        //         }
        //         threads.thread_nodes()[&iter_ptr].message()
        //     }) {
        //         h
        //     } else {
        //         continue;
        //     };

        //     let row_data = FolderConversationRowData::new(&"Subject placeholder");
        //     unsafe {
        //         (*row_data.as_ptr()).get_impl().subject.replace(Some(
        //             threads.thread_nodes()[&threads.thread_ref(thread).root()]
        //                 .message()
        //                 .as_ref()
        //                 .map(|m| envelopes.read().unwrap()[m].subject().to_string())
        //                 .unwrap_or_else(|| "None".to_string()),
        //         ));
        //     }

        //     self.threads_model.append(&row_data)
    }
}
