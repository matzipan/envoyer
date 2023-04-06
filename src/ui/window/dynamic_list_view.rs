use crate::models::folder_conversations_list::model::FolderModel;

use super::*;

use gtk::subclass::prelude::*;

// Implementation sub-module of the GObject
mod imp {
    use std::{cell::Cell, ops::Range};

    use gtk::{
        glib::{ParamSpec, ParamSpecEnum, ParamSpecObject, SignalHandlerId},
        Adjustment, ScrollablePolicy,
    };
    use once_cell::sync::Lazy;
    use tide::log::debug;

    use super::*;

    type RowWidgetType = crate::ui::window::folder_conversation_item::FolderConversationItem;

    pub enum Location {
        Top,
        Bottom,
    }

    pub enum Order {
        Forward,
        Reverse,
    }

    // The actual data structure that stores our values. This is not accessible
    // directly from the outside.
    #[derive(Default)]
    pub struct DynamicListView {
        horizontal_adjustment: RefCell<Option<Adjustment>>,
        hscroll_policy: Cell<Option<ScrollablePolicy>>,
        vertical_adjustment: RefCell<Option<Adjustment>>,
        vscroll_policy: Cell<Option<ScrollablePolicy>>,
        height_per_row: Cell<u32>,
        first_item: Cell<u32>,
        last_item: Cell<u32>,
        adjustment_value_changed_signal_handler_id: RefCell<Option<SignalHandlerId>>,
        conversations_list_model: RefCell<Option<FolderModel>>,
        factory_function: RefCell<Option<Box<dyn Fn(u32, &glib::Object) -> gtk::Widget + 'static>>>,
        activate_function: RefCell<Option<Rc<Box<dyn Fn(&super::DynamicListView, u32) + 'static>>>>,
    }

    impl DynamicListView {
        pub fn model(&self) -> Option<FolderModel> {
            let model_borrow = self.conversations_list_model.borrow();

            model_borrow.clone()
        }

        fn item_count(&self) -> u32 {
            let model_borrow = self.conversations_list_model.borrow();

            model_borrow.as_ref().map_or(0, |x| x.n_items())
        }

        fn total_height(&self) -> u32 {
            self.item_count() * self.height_per_row.get()
        }

        pub fn set_height_per_row(&self, height: u32) {
            self.height_per_row.set(height);
        }

        pub fn set_factory(&self, factory_function: impl Fn(u32, &glib::Object) -> gtk::Widget + 'static) {
            *self.factory_function.borrow_mut() = Some(Box::new(factory_function));
        }

        pub fn set_activate_function(&self, activate_function: impl Fn(&super::DynamicListView, u32) + 'static) {
            *self.activate_function.borrow_mut() = Some(Rc::new(Box::new(activate_function)));
        }

        pub fn set_conversations_list_model(&self, conversations_list_model: FolderModel) {
            *self.conversations_list_model.borrow_mut() = Some(conversations_list_model);
        }

        fn configure_adjustment(&self, height: u32) {
            let total_height = self.total_height();

            if let Some(vertical_adjustment) = self.vertical_adjustment.borrow().as_ref() {
                let signal_handler_id_cell = self.adjustment_value_changed_signal_handler_id.borrow();
                let signal_handler_id = signal_handler_id_cell.as_ref().expect("Signal handler should be set at this point");

                vertical_adjustment.block_signal(&signal_handler_id);

                vertical_adjustment.configure(
                    vertical_adjustment.value(),
                    0.0,
                    height.max(total_height) as f64,
                    0.01 * height as f64,
                    0.09 * height as f64,
                    height as f64,
                );

                vertical_adjustment.unblock_signal(&signal_handler_id);
            }
        }

        fn vertical_adjustment_value(&self) -> f64 {
            self.vertical_adjustment
                .borrow()
                .as_ref()
                .map_or(0f64, |adjustment| adjustment.value())
        }

        fn size_allocate_children(&self, width: i32) {
            let height_per_row = self.height_per_row.get();
            let vertical_adjustment_value = self.vertical_adjustment_value().floor() as u32;

            self.children_foreach(&Order::Forward, move |row| {
                let item_index = row.get_item_index();

                let allocation = gtk::Allocation::new(
                    0,
                    (item_index * height_per_row) as i32 - vertical_adjustment_value as i32,
                    width,
                    height_per_row as i32,
                );

                row.size_allocate(&allocation, -1);

                true
            });
        }

        fn children_foreach<F: Fn(&RowWidgetType) -> bool>(&self, order: &Order, f: F) {
            let obj = self.obj();
            let mut child_option = match order {
                Order::Forward => obj.first_child(),
                Order::Reverse => obj.last_child(),
            };

            while let Some(child) = child_option {
                let row = child.downcast_ref::<RowWidgetType>().unwrap();

                if !f(&row) {
                    break;
                }

                child_option = match order {
                    Order::Forward => child.next_sibling(),
                    Order::Reverse => obj.prev_sibling(),
                };
            }
        }

        fn children_count(&self) -> u32 {
            let obj = self.obj();

            let mut child_option = obj.first_child();

            let mut children_count = 0;

            while let Some(child) = child_option {
                children_count += 1;

                child_option = child.next_sibling();
            }

            return children_count;
        }

        fn remove_rows_in_index_range(&self, range: Range<u32>, removal_location: Location) {
            // We're reverting when location is bottom so we can match straight away
            let range_items: Vec<_> = match removal_location {
                Location::Top => range.collect(),
                Location::Bottom => range.rev().collect(),
            };

            let order = match removal_location {
                Location::Top => Order::Forward,
                Location::Bottom => Order::Reverse,
            };

            for item_index in range_items {
                self.children_foreach(&order, move |row| {
                    if row.get_item_index() == item_index {
                        row.unparent();

                        return false;
                    }

                    true
                });
            }
        }

        fn create_rows_in_index_range(&self, range: Range<u32>, creation_location: Location) {
            let factory_function_cell = self.factory_function.borrow();
            let activate_function_cell = self.activate_function.borrow();
            if let Some(factory_function) = factory_function_cell.as_ref() {
                if let Some(activate_function) = activate_function_cell.as_ref() {
                    let obj = self.obj();

                    // We're reverting when location is top so we can use the insert_after to
                    // prepend new items
                    let range_items: Vec<u32> = match creation_location {
                        Location::Top => range.rev().collect(),
                        Location::Bottom => range.collect(),
                    };

                    let store_borrow = self.conversations_list_model.borrow();
                    for item_index in range_items {
                        // It's okay to unwrap because we initialize at creation time
                        if let Some(item_data) = store_borrow.as_ref().unwrap().item(item_index) {
                            let row = factory_function(item_index, &item_data);

                            let allocation = gtk::Allocation::new(
                                0,
                                (item_index * self.height_per_row.get()) as i32,
                                obj.allocated_width(),
                                self.height_per_row.get() as i32,
                            );

                            let list_row_widget = row
                                .downcast_ref::<FolderConversationItem>()
                                .expect("Row is expected to be ListBoxRow");
                            let activate_function_clone = activate_function.clone();
                            let obj_clone = obj.clone();

                            list_row_widget.connect_activate(move || {
                                activate_function_clone(&obj_clone, item_index);
                            });

                            row.size_allocate(&allocation, -1);

                            match creation_location {
                                Location::Top => {
                                    row.insert_after(obj.upcast_ref::<gtk::Widget>(), gtk::Widget::NONE);
                                }
                                Location::Bottom => {
                                    row.insert_before(obj.upcast_ref::<gtk::Widget>(), gtk::Widget::NONE);
                                }
                            }
                        }
                    }
                }
            }
        }

        fn update_visible_children(&self) {
            let obj = self.obj();

            let height_per_row = self.height_per_row.get();
            let widget_height = obj.allocated_height() as u32;
            let vertical_adjustment_value = self.vertical_adjustment_value();

            let item_count = self.item_count();

            let previous_first_item = self.first_item.get();
            let previous_last_item = self.last_item.get();

            let current_first_item = (vertical_adjustment_value / height_per_row as f64).floor() as u32;
            let visible_items_count = widget_height / height_per_row + 2;
            let current_last_item = item_count.min(current_first_item + visible_items_count);

            match previous_first_item.cmp(&current_first_item) {
                std::cmp::Ordering::Less => {
                    let range = previous_first_item..current_first_item;

                    debug!("Remove top items {:?}", range);

                    self.remove_rows_in_index_range(range, Location::Top);
                }

                std::cmp::Ordering::Greater => {
                    let previous_first_item = previous_first_item.min(current_first_item + visible_items_count);
                    let range = current_first_item..previous_first_item;

                    debug!("Add top items {:?}", range);

                    self.create_rows_in_index_range(range, Location::Top);
                }
                _ => {}
            }

            match previous_last_item.cmp(&current_last_item) {
                std::cmp::Ordering::Less => {
                    let unclamped_previous_last_item = previous_last_item.max(current_last_item - visible_items_count);
                    // Without this clamping, the list of elements could end up have too many
                    // elements out of range at the top when scrolling in big increments.
                    let previous_last_item = unclamped_previous_last_item.max(current_first_item);
                    let range = previous_last_item..current_last_item;

                    debug!("Add bottom items {:?}", range);

                    self.create_rows_in_index_range(range, Location::Bottom);
                }
                std::cmp::Ordering::Greater => {
                    let range = current_last_item..previous_last_item;

                    debug!("Remove bottom items {:?}", range);

                    self.remove_rows_in_index_range(range, Location::Bottom);
                }
                _ => {}
            }

            std::assert!(
                self.children_count() <= visible_items_count,
                "There are more children than there can be visible. This is a bug"
            );

            self.first_item.set(current_first_item);
            self.last_item.set(current_last_item);
        }
    }

    // Basic declaration of our type for the GObject type system
    #[glib::object_subclass]
    impl ObjectSubclass for DynamicListView {
        const NAME: &'static str = "DynamicListView";
        type Type = super::DynamicListView;
        type ParentType = gtk::Widget;
        type Interfaces = (gtk::Scrollable,);
    }

    impl ObjectImpl for DynamicListView {
        fn constructed(&self) {
            self.parent_constructed();

            let obj = self.obj();

            obj.set_vexpand(true);
            obj.queue_allocate();
        }

        fn properties() -> &'static [ParamSpec] {
            static PROPERTIES: Lazy<Vec<ParamSpec>> = Lazy::new(|| {
                vec![
                    ParamSpecObject::builder::<Adjustment>("hadjustment").build(),
                    ParamSpecObject::builder::<Adjustment>("vadjustment").build(),
                    ParamSpecEnum::builder::<ScrollablePolicy>("hscroll-policy", ScrollablePolicy::Minimum).build(),
                    ParamSpecEnum::builder::<ScrollablePolicy>("vscroll-policy", ScrollablePolicy::Minimum).build(),
                ]
            });
            PROPERTIES.as_ref()
        }

        fn set_property(&self, _id: usize, value: &glib::Value, pspec: &ParamSpec) {
            let obj = self.obj();
            match pspec.name() {
                "hadjustment" => {
                    if let Ok(value) = value.get::<Adjustment>() {
                        *self.horizontal_adjustment.borrow_mut() = Some(value.clone());
                    }
                }
                "hscroll-policy" => {
                    if let Ok(value) = value.get::<ScrollablePolicy>() {
                        self.hscroll_policy.set(Some(value));
                    }
                }
                "vadjustment" => {
                    if let Ok(value) = value.get::<Adjustment>() {
                        *self.vertical_adjustment.borrow_mut() = Some(value.clone());

                        let widget = obj.clone();

                        let signal_handler_id = value.connect_value_changed(move |_| {
                            widget.queue_allocate();
                        });

                        self.adjustment_value_changed_signal_handler_id.replace(Some(signal_handler_id));
                    }
                }
                "vscroll-policy" => {
                    if let Ok(value) = value.get::<ScrollablePolicy>() {
                        self.vscroll_policy.set(Some(value));
                    }
                }
                _ => {}
            }
        }

        fn property(&self, _id: usize, pspec: &ParamSpec) -> glib::Value {
            match pspec.name() {
                "hadjustment" => self.horizontal_adjustment.borrow().to_value(),
                "hscroll-policy" => self.hscroll_policy.get().unwrap_or(ScrollablePolicy::Minimum).to_value(),
                "vadjustment" => self.vertical_adjustment.borrow().to_value(),
                "vscroll-policy" => self.vscroll_policy.get().unwrap_or(ScrollablePolicy::Minimum).to_value(),
                _ => unimplemented!(),
            }
        }
    }

    impl WidgetImpl for DynamicListView {
        fn measure(&self, orientation: gtk::Orientation, _for_size: i32) -> (i32, i32, i32, i32) {
            let total_height = self.total_height();

            match orientation {
                gtk::Orientation::Horizontal => (0, 0, -1, -1),
                gtk::Orientation::Vertical => (0, total_height as i32, -1, -1),
                _ => unimplemented!(),
            }
        }

        fn size_allocate(&self, width: i32, height: i32, baseline: i32) {
            let obj = self.obj();

            let allocation = gtk::Allocation::new(0, 0, width, height);
            obj.size_allocate(&allocation, baseline);

            self.configure_adjustment(height as u32);
            self.update_visible_children();
            self.size_allocate_children(width);

            obj.queue_draw();
        }
    }

    impl ScrollableImpl for DynamicListView {}
}

// The public part
glib::wrapper! {
    pub struct DynamicListView(ObjectSubclass<imp::DynamicListView>) @extends gtk::Widget, @implements gtk::Scrollable;
}
impl DynamicListView {
    pub fn new(
        height: u32,
        conversations_list_model: FolderModel,
        factory_function: impl Fn(u32, &glib::Object) -> gtk::Widget + 'static,
    ) -> DynamicListView {
        let instance = glib::Object::new::<DynamicListView>(&[]);

        let self_ = imp::DynamicListView::from_instance(&instance);

        self_.set_height_per_row(height);
        self_.set_conversations_list_model(conversations_list_model);
        self_.set_factory(factory_function);

        instance
    }

    pub fn connect_activate(&self, activate_function: impl Fn(&DynamicListView, u32) + 'static) {
        let self_ = imp::DynamicListView::from_instance(self);

        self_.set_activate_function(activate_function);
    }

    pub fn model(&self) -> Option<FolderModel> {
        let self_ = imp::DynamicListView::from_instance(self);

        self_.model()
    }
}
