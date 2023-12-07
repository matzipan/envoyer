use gtk::{gio, glib};

use gtk::prelude::*;

use glib::subclass::prelude::*;
use gtk::subclass::prelude::*;

use gtk::glib::subclass::Signal;

use std::cell::RefCell;
use std::rc::Rc;

use once_cell::sync::Lazy;

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
        impl ObjectImpl for FolderModel {
            fn signals() -> &'static [Signal] {
                static SIGNALS: Lazy<Vec<Signal>> = Lazy::new(|| vec![Signal::builder("folder-loaded").build()]);
                SIGNALS.as_ref()
            }
        }
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

        fn load_summaries(&self, folder: &models::Folder) -> Vec<models::MessageSummary> {
            let self_ = imp::FolderModel::from_obj(&self);

            return self_
                .store
                .borrow()
                .as_ref()
                .unwrap()
                .get_message_summaries_for_folder(folder)
                .expect("Unable to get message summary");
        }

        pub fn load_folder(self, folder: models::Folder) {
            let self_ = imp::FolderModel::from_obj(&self);

            self_.summaries.replace(Some(self.load_summaries(&folder)));

            self_.currently_loaded_folder.replace(Some(folder));

            self_.obj().emit_by_name::<()>("folder-loaded", &[]);
        }

        pub fn handle_new_messages_for_folder(&self, folder: &models::Folder) {
            let self_ = imp::FolderModel::from_obj(self);

            if let Some(currently_loaded_folder) = self_.currently_loaded_folder.borrow().as_ref() {
                if currently_loaded_folder.folder_name == folder.folder_name && currently_loaded_folder.identity_id == folder.identity_id {
                    let self_ = imp::FolderModel::from_obj(self);

                    let new_summaries = self.load_summaries(currently_loaded_folder);

                    let diffs = diff_summary_lists(&self_.summaries.borrow().as_ref().unwrap(), &new_summaries);

                    let changes = adjust_diffs_for_items_changed_notification(diffs);

                    self_.summaries.replace(Some(new_summaries));

                    for change in changes {
                        self.items_changed(change.position, change.removed, change.added);
                    }
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

#[derive(PartialEq, Debug)]
pub struct SummaryListsDiff {
    pub position: u32,
    pub removed: u32,
    pub added: u32,
}

fn diff_summary_lists(old_summaries: &Vec<models::MessageSummary>, new_summaries: &Vec<models::MessageSummary>) -> Vec<SummaryListsDiff> {
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
            let new_change = SummaryListsDiff {
                position: old_summaries_index_start as u32,
                removed: 0,
                added: (new_summaries_index_end - new_summaries_index_start) as u32,
            };

            diff.push(new_change);

            mismatch_state_machine = MismatchState::None;
        }
    }

    if new_summaries_cursor < new_summaries.len() {
        diff.push(SummaryListsDiff {
            position: old_summaries.len() as u32,
            removed: 0,
            added: (new_summaries.len() - new_summaries_cursor) as u32,
        });
    }

    diff
}

fn adjust_diffs_for_items_changed_notification(diffs: Vec<SummaryListsDiff>) -> Vec<SummaryListsDiff> {
    let mut changes = Vec::new();

    let mut accumulator: i32 = 0;

    for diff in diffs {
        changes.push(SummaryListsDiff {
            position: diff.position + accumulator as u32,
            removed: diff.removed,
            added: diff.added,
        });

        accumulator -= diff.removed as i32;
        accumulator += diff.added as i32;
    }

    changes
}

#[cfg(test)]
pub mod test {
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
    fn test_diff_summary_lists() {
        let old_summaries = vec![create_message_summary(0), create_message_summary(1)];

        let mut new_summaries = old_summaries.clone();

        assert_eq!(diff_summary_lists(&old_summaries, &new_summaries), vec![]);

        let mut new_summaries = old_summaries.clone();

        new_summaries.insert(1, create_message_summary(4));
        new_summaries.insert(2, create_message_summary(5));

        assert_eq!(
            diff_summary_lists(&old_summaries, &new_summaries),
            vec![SummaryListsDiff {
                position: 1,
                removed: 0,
                added: 2
            }]
        );

        let mut new_summaries = old_summaries.clone();

        new_summaries.insert(1, create_message_summary(4));
        new_summaries.insert(2, create_message_summary(5));

        new_summaries.push(create_message_summary(6));
        new_summaries.push(create_message_summary(7));

        assert_eq!(
            diff_summary_lists(&old_summaries, &new_summaries),
            vec![
                SummaryListsDiff {
                    position: 1,
                    removed: 0,
                    added: 2
                },
                SummaryListsDiff {
                    position: 2,
                    removed: 0,
                    added: 2
                }
            ]
        );

        let old_summaries = vec![create_message_summary(0), create_message_summary(1)];

        let mut new_summaries = old_summaries.clone();
        new_summaries.insert(0, create_message_summary(2));
        new_summaries.insert(1, create_message_summary(3));

        new_summaries.insert(3, create_message_summary(4));
        new_summaries.insert(4, create_message_summary(5));

        new_summaries.push(create_message_summary(6));
        new_summaries.push(create_message_summary(7));

        assert_eq!(
            diff_summary_lists(&old_summaries, &new_summaries),
            vec![
                SummaryListsDiff {
                    position: 0,
                    removed: 0,
                    added: 2
                },
                SummaryListsDiff {
                    position: 1,
                    removed: 0,
                    added: 2
                },
                SummaryListsDiff {
                    position: 2,
                    removed: 0,
                    added: 2
                }
            ]
        );
    }

    #[test]
    fn test_adjust_diffs_for_items_changed_notification() {
        let diffs = vec![SummaryListsDiff {
            position: 1,
            removed: 0,
            added: 2,
        }];

        assert_eq!(
            adjust_diffs_for_items_changed_notification(diffs),
            vec![SummaryListsDiff {
                position: 1,
                removed: 0,
                added: 2,
            }]
        );

        let diffs = vec![
            SummaryListsDiff {
                position: 0,
                removed: 0,
                added: 2,
            },
            SummaryListsDiff {
                position: 1,
                removed: 0,
                added: 2,
            },
            SummaryListsDiff {
                position: 2,
                removed: 0,
                added: 2,
            },
        ];

        assert_eq!(
            adjust_diffs_for_items_changed_notification(diffs),
            vec![
                SummaryListsDiff {
                    position: 0,
                    removed: 0,
                    added: 2,
                },
                SummaryListsDiff {
                    position: 3,
                    removed: 0,
                    added: 2,
                },
                SummaryListsDiff {
                    position: 6,
                    removed: 0,
                    added: 2,
                },
            ]
        );

        let diffs = vec![
            SummaryListsDiff {
                position: 0,
                removed: 1,
                added: 2,
            },
            SummaryListsDiff {
                position: 1,
                removed: 0,
                added: 2,
            },
            SummaryListsDiff {
                position: 2,
                removed: 3,
                added: 2,
            },
            SummaryListsDiff {
                position: 3,
                removed: 0,
                added: 1,
            },
        ];

        assert_eq!(
            adjust_diffs_for_items_changed_notification(diffs),
            vec![
                SummaryListsDiff {
                    position: 0,
                    removed: 1,
                    added: 2,
                },
                SummaryListsDiff {
                    position: 2,
                    removed: 0,
                    added: 2,
                },
                SummaryListsDiff {
                    position: 6,
                    removed: 3,
                    added: 2,
                },
                SummaryListsDiff {
                    position: 6,
                    removed: 0,
                    added: 1,
                },
            ]
        );
    }
}
