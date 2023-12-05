use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use std::cell::RefCell;
use std::rc::Rc;

use crate::models;
use crate::services;

pub mod model {
    use super::*;
    use row_data::ConversationRowData;
    mod imp {
        use super::*;

        #[derive(Debug)]
        pub struct FolderModel {
            pub store: Rc<RefCell<Option<Rc<services::Store>>>>,
            pub summaries: Rc<RefCell<Option<Vec<models::MessageSummary>>>>,
            pub currently_loaded_folder: Rc<RefCell<Option<models::Folder>>>,
        }
        // Basic declaration of our type for the GObject type system

        #[glib::object_subclass]
        impl ObjectSubclass for FolderModel {
            const NAME: &'static str = "FolderModel";
            type Type = super::FolderModel;
            type ParentType = glib::Object;
            type Interfaces = (gio::ListModel,);

            // Called once at the very beginning of instantiation
            fn new() -> Self {
                Self {
                    store: Default::default(),
                    summaries: Default::default(),
                    currently_loaded_folder: Default::default(),
                }
            }
        }
        impl ObjectImpl for FolderModel {}
        impl ListModelImpl for FolderModel {
            fn item_type(&self) -> glib::Type {
                ConversationRowData::static_type()
            }

            fn n_items(&self) -> u32 {
                match self.summaries.borrow().as_ref() {
                    Some(summaries) => summaries.len() as u32,
                    None => 0,
                }
            }

            fn item(&self, position: u32) -> Option<glib::Object> {
                let data = ConversationRowData::new();

                data.set_conversation(self.summaries.borrow().as_ref().unwrap()[position as usize].clone()); //@TODO should probably be an Rc to the item

                Some(data.clone().upcast::<glib::Object>())
            }
        }
    }
    // Public part of the Model type.
    glib::wrapper! {
        pub struct FolderModel(ObjectSubclass<imp::FolderModel>) @implements gio::ListModel;
    }
    // Constructor for new instances. This simply calls glib::Object::new()
    impl FolderModel {
        #[allow(clippy::new_without_default)]
        pub fn new() -> FolderModel {
            glib::Object::new::<FolderModel>()
        }

        pub fn attach_store(self, store: Rc<services::Store>) {
            let self_ = imp::FolderModel::from_obj(&self);

            self_.store.replace(Some(store));
        }

        pub fn load_folder(self, folder: models::Folder) {
            let self_ = imp::FolderModel::from_obj(&self);

            self_.currently_loaded_folder.replace(Some(folder));

            self.update_list();
        }

        fn update_list(&self) {
            let self_ = imp::FolderModel::from_obj(self);

            if let Some(currently_loaded_folder) = self_.currently_loaded_folder.borrow().as_ref() {
                let previous_count = self_.n_items();

                self_.summaries.replace(Some(
                    self_
                        .store
                        .borrow()
                        .as_ref()
                        .unwrap()
                        .get_message_summaries_for_folder(currently_loaded_folder)
                        .expect("Unable to get message summary"),
                ));

                let new_count = self_.n_items();

                self.items_changed(0, previous_count, new_count);
            }
        }

        pub fn handle_new_messages_for_folder(self, folder: &models::Folder) {
            let self_ = imp::FolderModel::from_obj(&self);

            if let Some(currently_loaded_folder) = self_.currently_loaded_folder.borrow().as_ref() {
                if currently_loaded_folder.folder_name == folder.folder_name && currently_loaded_folder.identity_id == folder.identity_id {
                    // This creates ugly flicker and loss of selection. Should
                    // be fixed with issue #227
                    // self.update_list();
                }
            }
        }
    }
}

// This row data wrapper is needed because the FolderModel get_item_type method
// needs to have a GObject type to return to the bind_model method
pub mod row_data {
    use super::*;

    // Implementation sub-module of the GObject
    mod imp {
        use super::*;

        // The actual data structure that stores our values. This is not accessible
        // directly from the outside.
        pub struct ConversationRowData {
            pub conversation: Rc<RefCell<Option<models::MessageSummary>>>,
        }

        // Basic declaration of our type for the GObject type system
        #[glib::object_subclass]
        impl ObjectSubclass for ConversationRowData {
            const NAME: &'static str = "ConversationRowData";
            type Type = super::ConversationRowData;
            type ParentType = glib::Object;
            // Called once at the very beginning of instantiation of each instance and
            // creates the data structure that contains all our state
            fn new() -> Self {
                Self {
                    conversation: Default::default(),
                }
            }
        }
        impl ObjectImpl for ConversationRowData {}
    }

    // The public part
    glib::wrapper! {
        pub struct ConversationRowData(ObjectSubclass<imp::ConversationRowData>);
    }
    impl ConversationRowData {
        pub fn new() -> ConversationRowData {
            glib::Object::new::<ConversationRowData>()
        }
        pub fn set_conversation(&self, conversation: models::MessageSummary) {
            let self_ = imp::ConversationRowData::from_obj(self);
            self_.conversation.replace(Some(conversation));
        }
        pub fn get_conversation(&self) -> Rc<RefCell<Option<models::MessageSummary>>> {
            let self_ = imp::ConversationRowData::from_obj(self);
            self_.conversation.clone()
        }
    }
}

#[derive(PartialEq, Debug)]
enum MismatchState {
    None,
    Started {
        old_summaries_index_start: usize,
        new_summaries_index_start: usize,
    },
    Ended {
        old_summaries_index_start: usize,
        new_summaries_index_start: usize,
        new_summaries_index_end: usize,
    },
}

fn diff_summaries(old_summaries: &Vec<models::MessageSummary>, new_summaries: &Vec<models::MessageSummary>) -> Vec<(usize, usize, usize)> {
    //@TODO at the moment handling only newly added items
    let mut new_summaries_cursor = 0;

    let mut mismatch_state_machine = MismatchState::None;

    let mut diff = Vec::new();

    for (old_summaries_index, old_item) in old_summaries.iter().enumerate() {
        for (new_summaries_index, new_item) in new_summaries.iter().enumerate().skip(new_summaries_cursor) {
            if new_item.message_id == old_item.message_id {
                new_summaries_cursor = new_summaries_index + 1;

                if let MismatchState::Started {
                    old_summaries_index_start,
                    new_summaries_index_start,
                } = mismatch_state_machine
                {
                    mismatch_state_machine = MismatchState::Ended {
                        old_summaries_index_start,
                        new_summaries_index_start,
                        new_summaries_index_end: new_summaries_index,
                    };
                }
                break;
            } else if MismatchState::None == mismatch_state_machine {
                mismatch_state_machine = MismatchState::Started {
                    old_summaries_index_start: old_summaries_index,
                    new_summaries_index_start: new_summaries_index,
                };
            }
        }

        if let MismatchState::Ended {
            old_summaries_index_start,
            new_summaries_index_start,
            new_summaries_index_end,
        } = mismatch_state_machine
        {
            let new_change = (old_summaries_index_start, 0, new_summaries_index_end - new_summaries_index_start);
            diff.push(new_change);

            mismatch_state_machine = MismatchState::None;
        }
    }

    if new_summaries_cursor < new_summaries.len() {
        diff.push((old_summaries.len(), 0, new_summaries.len() - new_summaries_cursor));
    }

    diff
}

#[cfg(test)]
pub mod test {
    use chrono::NaiveDateTime;

    use crate::models::MessageSummary;

    use super::*;

    fn create_message_summary(id: i32) -> models::MessageSummary {
        models::MessageSummary {
            id,
            message_id: format!("id_{}", id).to_string(),
            subject: format!("subject {}", id).to_string(),
            from: format!("from {}", id).to_string(),
            time_received: chrono::offset::Utc::now().naive_utc(),
        }
    }

    #[test]
    fn test_diff_summaries() {
        let old_summaries = vec![create_message_summary(0), create_message_summary(1)];

        let mut new_summaries = old_summaries.clone();

        assert_eq!(diff_summaries(&old_summaries, &new_summaries), vec![]);

        let mut new_summaries = old_summaries.clone();

        new_summaries.insert(1, create_message_summary(4));
        new_summaries.insert(2, create_message_summary(5));

        assert_eq!(diff_summaries(&old_summaries, &new_summaries), vec![(1, 0, 2)]);

        let mut new_summaries = old_summaries.clone();

        new_summaries.insert(1, create_message_summary(4));
        new_summaries.insert(2, create_message_summary(5));

        new_summaries.push(create_message_summary(6));
        new_summaries.push(create_message_summary(7));

        assert_eq!(diff_summaries(&old_summaries, &new_summaries), vec![(1, 0, 2), (2, 0, 2)]);

        let old_summaries = vec![create_message_summary(0), create_message_summary(1)];

        let mut new_summaries = old_summaries.clone();
        new_summaries.insert(0, create_message_summary(2));
        new_summaries.insert(1, create_message_summary(3));

        new_summaries.insert(3, create_message_summary(4));
        new_summaries.insert(4, create_message_summary(5));

        new_summaries.push(create_message_summary(6));
        new_summaries.push(create_message_summary(7));

        assert_eq!(
            diff_summaries(&old_summaries, &new_summaries),
            vec![(0, 0, 2), (1, 0, 2), (2, 0, 2)]
        );
    }
}
