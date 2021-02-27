use gtk;
use gtk::gdk;
use gtk::prelude::*;
use log::info;

use std::sync::{Arc, Mutex};

use crate::models;

#[derive(Clone)]
pub struct Window {
    pub gtk_window: gtk::ApplicationWindow,
    pub threads_list_box: gtk::ListBox,
    pub identities: Arc<Mutex<Vec<models::Identity>>>,
    pub model: models::folder_conversations_list::model::Model,
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

        let scroll_box = gtk::ScrolledWindow::new(gtk::NONE_ADJUSTMENT, gtk::NONE_ADJUSTMENT);
        scroll_box.set_vexpand(true);
        scroll_box.set_hexpand(true);
        scroll_box.add(&threads_list_box);

        gtk_window.add(&scroll_box);

        threads_list_box.connect_row_selected(|_, list_box_row| info!("{}", list_box_row.unwrap().get_index()));

        let model = models::folder_conversations_list::model::Model::new();
        threads_list_box.bind_model(Some(&model), |item| {
            let item = item
                .downcast_ref::<models::folder_conversations_list::row_data::RowData>()
                .expect("Row data is of wrong type");

            let box_row = gtk::ListBoxRow::new();

            let label = gtk::Label::new(None);

            label.set_text(item.get_subject().as_ref());

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

    pub fn show_threads(&self, threads: Vec<models::Message>) {
        for thread in threads {
            let data = models::folder_conversations_list::row_data::RowData::new();

            data.set_subject(&thread.subject);

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
