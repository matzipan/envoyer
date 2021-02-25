use gtk;
use gtk::glib::clone;
use gtk::prelude::*;
use gtk::{gdk, gio, glib};
use log::info;

use std::sync::{Arc, Mutex};

use crate::identity;
use crate::models;

mod model {
    use super::*;
    use glib::subclass::prelude::*;
    use gtk::subclass::prelude::*;
    use row_data::RowData;
    mod imp {
        use super::*;
        use glib::subclass;
        use std::cell::RefCell;
        #[derive(Debug)]
        pub struct Model(pub RefCell<Vec<RowData>>);

        // Basic declaration of our type for the GObject type system
        impl ObjectSubclass for Model {
            const NAME: &'static str = "Model";
            type Type = super::Model;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);
            type Instance = subclass::simple::InstanceStruct<Self>;
            type Class = subclass::simple::ClassStruct<Self>;

            glib::object_subclass!();

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self(RefCell::new(Vec::new()))
            }
        }

        impl ObjectImpl for Model {}

        impl ListModelImpl for Model {
            fn get_item_type(&self, _list_model: &Self::Type) -> glib::Type {
                RowData::static_type()
            }
            fn get_n_items(&self, _list_model: &Self::Type) -> u32 {
                self.0.borrow().len() as u32
            }
            fn get_item(&self, _list_model: &Self::Type, position: u32) -> Option<glib::Object> {
                self.0.borrow().get(position as usize).map(|o| o.clone().upcast::<glib::Object>())
            }
        }
    }

    // Public part of the Model type.
    glib::wrapper! {
        pub struct Model(ObjectSubclass<imp::Model>) @implements gio::ListModel;
    }

    // Constructor for new instances. This simply calls glib::Object::new()
    impl Model {
        #[allow(clippy::new_without_default)]
        pub fn new() -> Model {
            glib::Object::new(&[]).expect("Failed to create Model")
        }

        pub fn append(&self, obj: &RowData) {
            let self_ = imp::Model::from_instance(self);
            let index = {
                // Borrow the data only once and ensure the borrow guard is dropped
                // before we emit the items_changed signal because the view
                // could call get_item / get_n_item from the signal handler to update its state
                let mut data = self_.0.borrow_mut();
                data.push(obj.clone());
                data.len() - 1
            };
            // Emits a signal that 1 item was added, 0 removed at the position index
            self.items_changed(index as u32, 0, 1);
        }

        pub fn remove(&self, index: u32) {
            let self_ = imp::Model::from_instance(self);
            self_.0.borrow_mut().remove(index as usize);
            // Emits a signal that 1 item was removed, 0 added at the position index
            self.items_changed(index, 1, 0);
        }
    }
}

// Our GObject subclass for carrying a name and count for the ListBox model
//
// Subject is stored in a RefCell to allow for interior mutability and is
// exposed via normal GObject properties. This allows us to use property
// bindings below to bind the values with what widgets display in the UI
mod row_data {
    use super::*;

    use glib::subclass;
    use glib::subclass::prelude::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;
        use std::cell::RefCell;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct RowData {
            subject: RefCell<Option<String>>,
        }

        // Basic declaration of our type for the GObject type system
        impl ObjectSubclass for RowData {
            const NAME: &'static str = "RowData";
            type Type = super::RowData;
            type ParentType = glib::Object;
            type Interfaces = ();
            type Instance = subclass::simple::InstanceStruct<Self>;
            type Class = subclass::simple::ClassStruct<Self>;

            glib::object_subclass!();

            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    subject: RefCell::new(None),
                }
            }
        }

        impl ObjectImpl for RowData {
            fn properties() -> &'static [glib::ParamSpec] {
                use once_cell::sync::Lazy;
                static PROPERTIES: Lazy<Vec<glib::ParamSpec>> = Lazy::new(|| {
                    vec![glib::ParamSpec::string(
                        "subject",
                        "Subject",
                        "Subject",
                        None, // Default value
                        glib::ParamFlags::READWRITE,
                    )]
                });

                PROPERTIES.as_ref()
            }

            fn set_property(&self, _obj: &Self::Type, _id: usize, value: &glib::Value, pspec: &glib::ParamSpec) {
                match pspec.get_name() {
                    "subject" => {
                        let subject = value.get().expect("type conformity checked by `Object::set_property`");
                        self.subject.replace(subject);
                    }
                    _ => unimplemented!(),
                }
            }

            fn get_property(&self, _obj: &Self::Type, _id: usize, pspec: &glib::ParamSpec) -> glib::Value {
                match pspec.get_name() {
                    "subject" => self.subject.borrow().to_value(),
                    _ => unimplemented!(),
                }
            }
        }
    }

    // Public part of the RowData type. This behaves like a normal gtk-rs-style GObject
    // binding
    glib::wrapper! {
        pub struct RowData(ObjectSubclass<imp::RowData>);
    }

    // Constructor for new instances. This simply calls glib::Object::new() with
    // initial values for our two properties and then returns the new instance
    impl RowData {
        pub fn new(name: &str) -> RowData {
            glib::Object::new(&[("subject", &name)]).expect("Failed to create row data")
        }
    }
}

#[derive(Clone)]
pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    pub threads_list_box: gtk::ListBox,
    pub identities: Arc<Mutex<Vec<identity::Identity>>>,
    pub model: model::Model,
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

        threads_list_box.connect_row_selected(|_, list_box_row| info!("{}", list_box_row.unwrap().get_index()));

        // Create our list store and specify that the type stored in the
        // list should be the RowData GObject we define at the bottom
        let model = model::Model::new();
        threads_list_box.bind_model(Some(&model), |item| {
            let item = item.downcast_ref::<row_data::RowData>().expect("Row data is of wrong type");

            let box_row = gtk::ListBoxRow::new();

            let label = gtk::Label::new(Some(
                &item
                    .get_property("subject")
                    .expect("Could not read subject property")
                    .get::<&str>()
                    .expect("BLA")
                    .expect("BLA"),
            ));

            box_row.add(&label);

            box_row.show_all();

            box_row.upcast::<gtk::Widget>()
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

    pub fn load(&self, threads: Vec<models::Message>) {
        for thread in threads {
            self.model.append(&row_data::RowData::new(&thread.subject));
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
