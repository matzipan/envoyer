extern crate gdk;
extern crate gio;
extern crate gtk;

use gtk::prelude::*;

use log::info;

use std::collections::HashMap;
use std::sync::{Arc, Mutex, RwLock};

use crate::identity;

#[derive(Clone)]
pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    pub threads_model: gio::ListStore,
    pub threads_list_box: gtk::ListBox,
    pub identities: Arc<Mutex<Vec<identity::Identity>>>,
}

use glib::translate::*;

use std::cell::RefCell;

use glib::subclass;
use glib::subclass::prelude::*;
mod imp {
    use super::*;
    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    pub struct FolderConversationRowData {
        pub subject: RefCell<Option<String>>,
    }

    // GObject property definitions for our two values
    static PROPERTIES: [subclass::Property; 1] = [subclass::Property("subject", |subject| {
        glib::ParamSpec::string(
            subject,
            "Subject",
            "Subject",
            None, // Default value
            glib::ParamFlags::READWRITE,
        )
    })];
    // Basic declaration of our type for the GObject type system
    impl ObjectSubclass for FolderConversationRowData {
        const NAME: &'static str = "FolderConversationRowData";
        type ParentType = glib::Object;
        type Instance = subclass::simple::InstanceStruct<Self>;
        type Class = subclass::simple::ClassStruct<Self>;

        glib_object_subclass!();

        // Called exactly once before the first instantiation of an instance. This
        // sets up any type-specific things, in this specific case it installs the
        // properties so that GObject knows about their existence and they can be
        // used on instances of our type
        fn class_init(klass: &mut Self::Class) {
            klass.install_properties(&PROPERTIES);
        }

        // Called once at the very beginning of instantiation of each instance and
        // creates the data structure that contains all our state
        fn new() -> Self {
            Self {
                subject: RefCell::new(None),
            }
        }
    }

    impl ObjectImpl for FolderConversationRowData {
        glib_object_impl!();

        fn set_property(&self, _obj: &glib::Object, id: usize, value: &glib::Value) {
            let prop = &PROPERTIES[id];

            match *prop {
                subclass::Property("subject", ..) => {
                    let subject = value.get().expect("type conformity checked by `Object::set_property`");
                    self.subject.replace(subject);
                }
                _ => unimplemented!(),
            }
        }

        fn get_property(&self, _obj: &glib::Object, id: usize) -> Result<glib::Value, ()> {
            let prop = &PROPERTIES[id];

            match *prop {
                subclass::Property("subject", ..) => Ok(self.subject.borrow().to_value()),
                _ => unimplemented!(),
            }
        }
    }
}

// Public part of the RowData type. This behaves like a normal gtk-rs-style GObject
// binding
glib_wrapper! {
    pub struct FolderConversationRowData(Object<subclass::simple::InstanceStruct<imp::FolderConversationRowData>, subclass::simple::ClassStruct<imp::FolderConversationRowData>, RowDataClass>);

    match fn {
        get_type => || imp::FolderConversationRowData::get_type().to_glib(),
    }
}

// Constructor for new instances. This simply calls glib::Object::new() with
// initial values for our two properties and then returns the new instance
impl FolderConversationRowData {
    pub fn new(subject: &str) -> FolderConversationRowData {
        glib::Object::new(Self::static_type(), &[("subject", &subject)])
            .expect("Failed to create row data")
            .downcast()
            .expect("Created row data is of wrong type")
    }
}

impl Window {
    pub fn new(application: &gtk::Application, identities: Arc<Mutex<Vec<identity::Identity>>>) -> Window {
        //@TODO set icon
        let gtk_window = gtk::ApplicationWindow::new(application);
        let header = gtk::HeaderBar::new();
        header.set_title(Some("Envoyer"));
        header.set_show_close_button(true);
        gtk_window.set_titlebar(Some(&header));
        gtk_window.set_title("Envoyer");
        gtk_window.set_wmclass("envoyer", "Envoyer");
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

        let scroll_box = gtk::ScrolledWindow::new(gtk::NONE_ADJUSTMENT, gtk::NONE_ADJUSTMENT);
        scroll_box.set_vexpand(true);
        scroll_box.set_hexpand(true);
        scroll_box.add(&threads_list_box);

        gtk_window.add(&scroll_box);

        let threads_model = gio::ListStore::new(FolderConversationRowData::static_type());

        threads_list_box.bind_model(Some(&threads_model), move |item| {
            let box_ = gtk::ListBoxRow::new();
            let item = item.downcast_ref::<FolderConversationRowData>().expect("Row data is of wrong type");

            let hbox = gtk::Box::new(gtk::Orientation::Horizontal, 5);

            let label = gtk::Label::new(None);
            item.bind_property("subject", &label, "label")
                .flags(glib::BindingFlags::DEFAULT | glib::BindingFlags::SYNC_CREATE)
                .build();
            hbox.pack_start(&label, true, true, 0);

            box_.add(&hbox);

            box_.show_all();

            box_.upcast::<gtk::Widget>()
        });

        threads_list_box.connect_row_selected(|_, list_box_row| info!("{}", list_box_row.unwrap().get_index()));

        Self {
            gtk_window,
            threads_model,
            threads_list_box,
            identities,
        }
    }

    pub fn show(&self) {
        self.gtk_window.show_all();
        self.gtk_window.present();
    }

    pub fn load(&self) {
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