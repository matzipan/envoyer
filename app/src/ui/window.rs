pub mod conversation_message_item;
pub mod dynamic_list_view;
pub mod folder_conversation_item;
pub mod folders_list_item;
pub mod message_view;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib, gsk, pango};

use adw::subclass::prelude::*;

use log::info;

use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::CString;
use std::hash::Hash;
use std::rc::Rc;

use crate::bindings;
use crate::config::{APP_ID, PROFILE};
use crate::controllers::{Application, ApplicationMessage, ApplicationProfile};
use crate::models;
use crate::models::folder_conversations_list::row_data::ConversationRowData;

use self::dynamic_list_view::DynamicListView;
use self::folder_conversation_item::FolderConversationItem;

use self::message_view::MessageView;

use crate::models::folders_list::get_folder_presentation_name;

mod imp {
    use gtk::{
        glib::{ParamSpec, Value},
        CompositeTemplate,
    };

    use super::*;

    #[derive(glib::Properties, CompositeTemplate)]
    #[properties(wrapper_type = super::Window)]
    #[template(resource = "/com/github/matzipan/envoyer/window.ui")]
    pub struct Window {
        #[property(get, set, construct_only)]
        pub folders_list_model: RefCell<Option<models::folders_list::model::FolderListModel>>,
        #[property(get, set, construct_only)]
        pub conversations_list_model: RefCell<Option<models::folder_conversations_list::model::FolderModel>>,
        #[property(get, set, construct_only)]
        pub conversation_model: RefCell<Option<models::conversation_messages_list::model::ConversationModel>>,
        pub settings: gio::Settings,
        pub sender: Rc<RefCell<Option<glib::Sender<ApplicationMessage>>>>,
        #[template_child]
        pub threads_list_view: TemplateChild<DynamicListView>,
        #[template_child]
        pub folders_list_view: TemplateChild<gtk::ListView>,
        #[template_child]
        pub conversation_viewer_stack: TemplateChild<gtk::Stack>,
        #[template_child]
        pub conversation_viewer_spinner: TemplateChild<gtk::Spinner>,
        #[template_child]
        pub conversation_viewer_list_box: TemplateChild<gtk::ListBox>,
    }

    impl Default for Window {
        fn default() -> Self {
            Self {
                folders_list_model: Default::default(),
                conversations_list_model: Default::default(),
                conversation_model: Default::default(),
                settings: gio::Settings::new(APP_ID),
                sender: Default::default(),
                threads_list_view: Default::default(),
                folders_list_view: Default::default(),
                conversation_viewer_stack: Default::default(),
                conversation_viewer_spinner: Default::default(),
                conversation_viewer_list_box: Default::default(),
            }
        }
    }

    #[glib::object_subclass]
    impl ObjectSubclass for Window {
        const NAME: &'static str = "Window";
        type Type = super::Window;
        type ParentType = adw::ApplicationWindow;

        fn class_init(klass: &mut Self::Class) {
            DynamicListView::ensure_type();

            klass.bind_template();
            klass.bind_template_callbacks();
        }

        fn instance_init(obj: &glib::subclass::InitializingObject<Self>) {
            obj.init_template();
        }
    }

    impl ObjectImpl for Window {
        fn properties() -> &'static [ParamSpec] {
            Self::derived_properties()
        }

        fn set_property(&self, id: usize, value: &Value, pspec: &ParamSpec) {
            self.derived_set_property(id, value, pspec)
        }

        fn property(&self, id: usize, pspec: &ParamSpec) -> Value {
            self.derived_property(id, pspec)
        }

        fn constructed(&self) {
            self.parent_constructed();
            let obj = self.obj();

            if PROFILE == ApplicationProfile::Devel {
                obj.add_css_class("devel");
            }

            // Load latest window state
            obj.load_window_size();

            let conversation_model_borrow = self.conversation_model.borrow();
            let conversation_model = conversation_model_borrow.as_ref().expect("Conversation model not available");

            let folders_list_model_borrow = self.folders_list_model.borrow();
            let folders_list_model = folders_list_model_borrow.as_ref().expect("Folder list model not available");

            let conversations_list_model_borrow = self.conversations_list_model.borrow();
            let conversations_list_model = conversations_list_model_borrow
                .as_ref()
                .expect("Conversations list model not available");

            let folders_list_factory = gtk::SignalListItemFactory::new();
            folders_list_factory.connect_bind(move |_, list_item| {
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

                name_label.set_text(get_folder_presentation_name(folder));
                name_label.set_halign(gtk::Align::Start);

                box_item.append(&name_label);

                list_item.set_child(Some(&box_item));
            });

            let folders_list_selection_model = gtk::NoSelection::new(Some(folders_list_model.clone()));

            self.folders_list_view.get().set_model(Some(&folders_list_selection_model));
            self.folders_list_view.get().set_factory(Some(&folders_list_factory));

            self.threads_list_view
                .get()
                .set_conversations_list_model(conversations_list_model.clone());
            self.threads_list_view.get().set_factory(move |item_index, item| {
                let item_data = item
                    .downcast_ref::<models::folder_conversations_list::row_data::ConversationRowData>()
                    .expect("Row data is of wrong type");
                let conversation_rc = item_data.get_conversation();
                let conversation_borrow = conversation_rc.borrow();
                let conversation = conversation_borrow.as_ref().expect("Model contents invalid");

                let box_row = FolderConversationItem::new_with_item_index_and_conversation(item_index, &conversation);

                box_row.upcast::<gtk::Widget>()
            });

            let conversation_viewer_stack = self.conversation_viewer_stack.get().clone();
            let conversation_viewer_spinner = self.conversation_viewer_spinner.get().clone();

            conversation_model.connect_is_loading(move |args| {
                let is_loading = args[1].get::<bool>().expect("The is_loading value needs to be of type `bool`.");

                if is_loading {
                    conversation_viewer_stack.set_visible_child_name("loading");
                    conversation_viewer_spinner.start();
                } else {
                    conversation_viewer_stack.set_visible_child_name("conversation-viewer");
                    conversation_viewer_spinner.stop();
                }

                None
            });

            self.conversation_viewer_list_box
                .get()
                .bind_model(Some(conversation_model), |item| {
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

                    let view = MessageView::new();

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
        }
    }

    impl WidgetImpl for Window {}
    impl WindowImpl for Window {
        // Save window state on delete event
        fn close_request(&self) -> glib::Propagation {
            if let Err(err) = self.obj().save_window_size() {
                log::warn!("Failed to save window state, {}", &err);
            }

            // Pass close request on to the parent
            self.parent_close_request()
        }
    }

    impl ApplicationWindowImpl for Window {}
    impl AdwApplicationWindowImpl for Window {}

    #[gtk::template_callbacks]
    impl Window {
        #[template_callback]
        fn threads_list_view_activate(&self, position: u32) {
            let model = self.threads_list_view.get().model().unwrap();
            let item = model.item(position);

            if let Some(item) = item {
                let item = item.downcast_ref::<ConversationRowData>().expect("Row data is of the wrong type");
                let conversation_rc = item.get_conversation();
                let conversation_borrow = conversation_rc.borrow();
                let conversation = conversation_borrow.as_ref().expect("Model contents invalid");

                let message = conversation;

                info!("Selected conversation with subject \"{}\"", message.subject);

                self.sender
                    .borrow()
                    .as_ref()
                    .expect("Message sender not available")
                    .send(ApplicationMessage::ShowConversation {
                        conversation: message.clone(),
                    })
                    .expect("Unable to send application message");
            } else {
                // application.unload_current_conversation_thread ();
            }
        }

        #[template_callback]
        fn folders_list_activate(&self, position: u32) {
            let model = self.folders_list_view.get().model().unwrap();
            let item = model.item(position);

            if let Some(item) = item {
                let item = item
                    .downcast_ref::<models::folders_list::row_data::FolderRowData>()
                    .expect("List box row is of wrong type");

                let folder_rc = item.get_folder();
                let folder_borrow = folder_rc.borrow();
                let folder = folder_borrow.as_ref().expect("Model contents invalid");

                info!("Selected folder with name \"{}\"", folder.folder_name);

                self.sender
                    .borrow()
                    .as_ref()
                    .expect("Message sender not available")
                    .send(ApplicationMessage::ShowFolder { folder: folder.clone() })
                    .expect("Unable to send application message");
            } else {
                // application.unload_current_folder ();
            }
        }
    }
}

glib::wrapper! {
    pub struct Window(ObjectSubclass<imp::Window>)
        @extends gtk::Widget, gtk::Window, gtk::ApplicationWindow, adw::ApplicationWindow,
        @implements gio::ActionMap, gio::ActionGroup, gtk::Root;
}

impl Window {
    pub fn new(
        application: &Application,
        sender: glib::Sender<ApplicationMessage>,
        folders_list_model: &models::folders_list::model::FolderListModel,
        conversations_list_model: &models::folder_conversations_list::model::FolderModel,
        conversation_model: &models::conversation_messages_list::model::ConversationModel,
    ) -> Self {
        let window: Self = glib::Object::builder()
            .property("application", application)
            .property("folders-list-model", folders_list_model)
            .property("conversations-list-model", conversations_list_model)
            .property("conversation-model", conversation_model)
            .build();

        let imp = window.imp();

        imp.sender.replace(Some(sender));

        window
    }

    fn save_window_size(&self) -> Result<(), glib::BoolError> {
        let imp = self.imp();

        let (width, height) = self.default_size();

        imp.settings.set_int("window-width", width)?;
        imp.settings.set_int("window-height", height)?;

        //@TODO handle position too

        imp.settings.set_boolean("is-maximized", self.is_maximized())?;

        Ok(())
    }

    fn load_window_size(&self) {
        let imp = self.imp();

        let width = imp.settings.int("window-width");
        let height = imp.settings.int("window-height");
        let is_maximized = imp.settings.boolean("is-maximized");

        //@TODO handle position too

        self.set_default_size(width, height);

        if is_maximized {
            self.maximize();
        }
    }
    // public new void grab_focus () {
    //     listbox.grab_focus ();
    // }
}
