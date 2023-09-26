use super::*;

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
        glib::Object::new::<MessageView>()
    }

    pub fn load_content(&self, content: &String) {
        let self_ = imp::MessageView::from_obj(self);

        let master_stylesheet = include_str!("message_view_stylesheet.css");
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
