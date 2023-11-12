use gtk::prelude::*;
use gtk::{gdk, graphene, gsk, pango};



use log::debug;
use std::ffi::{CStr, CString};

use bitflags::bitflags;

bitflags! {
    #[repr(C)]
    pub struct FontOptions: u32 {
        const ITALIC = 1;
        const UNDERLINE = 1 << 1;
        const LINETHROUGH = 1 << 2;
        const OVERLINE = 1 << 3;
    }
}

#[repr(C)]
pub struct WebColor {
    pub red: u8,
    pub green: u8,
    pub blue: u8,
    pub alpha: u8,
}

#[repr(C)]
pub struct Position {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

#[repr(C)]
pub struct FontMetrics {
    pub ascent: i32,
    pub descent: i32,
    pub height: i32,
    pub x_height: i32,
}

pub struct Callbacks {
    next_font_key: usize,
    face_name_to_font_description_key_map: std::collections::HashMap<String, usize>,
    font_description_map: std::collections::HashMap<usize, pango::FontDescription>,
    default_font: CString,
    render_nodes: Vec<gsk::RenderNode>,
}

impl Callbacks {
    pub fn new() -> Self {
        Self {
            next_font_key: 1,
            font_description_map: Default::default(),
            face_name_to_font_description_key_map: Default::default(),
            default_font: CString::new("DejaVu Sans").unwrap(),
            render_nodes: Default::default(),
        }
    }

    pub fn nodes(&self) -> &Vec<gsk::RenderNode> {
        &self.render_nodes
    }

    pub fn clear_nodes(&mut self) {
        self.render_nodes.clear()
    }

    #[no_mangle]
    pub extern "C" fn draw_text(&mut self, hdc: usize, text: *const libc::c_char, font: usize, color: WebColor, position: Position) {
        let c_str = unsafe { CStr::from_ptr(text) };

        let text = c_str.to_str().unwrap();

        if text.trim().len() == 0 {
            debug!("Skipping drawing whitespace");

            return;
        } else {
            debug!("Draw text \"{}\" with font id {}", text, font);
        }

        if let Some(font_description) = self.font_description_map.get(&font) {
            debug!("Font found");

            let font_map = pangocairo::FontMap::default();
            let context = font_map.create_context();

            let font = context.load_font(&font_description).unwrap();

            let layout = pango::Layout::new(&context);

            layout.set_text(c_str.to_str().unwrap());
            layout.set_font_description(Some(font_description));

            let mut layout_iter = layout.iter();

            let glyph_item = layout_iter.run().unwrap();

            let mut glyph_string = glyph_item.glyph_string();
            let bottom_left_point = graphene::Point::new(
                (position.x as f32) / pango::SCALE as f32,
                (position.y + position.height - layout.height()) as f32 / pango::SCALE as f32,
            );

            let color = gdk::RGBA::new(
                color.red as f32 / u8::MAX as f32,
                color.green as f32 / u8::MAX as f32,
                color.blue as f32 / u8::MAX as f32,
                color.alpha as f32 / u8::MAX as f32,
            );

            self.render_nodes.push(
                gsk::TextNode::new(&font, &mut glyph_string, &color, &bottom_left_point)
                    .unwrap()
                    .upcast(),
            );
        }
    }

    pub fn populate_font_metrics(&self, font_description_key: &usize, font_metrics: *mut FontMetrics) {
        let font_description = self.font_description_map.get(font_description_key).unwrap();

        let font_map = pangocairo::FontMap::default();
        let context = font_map.create_context();
        context.set_font_description(Some(&font_description));

        let font = context.load_font(&font_description).unwrap();

        let (ink_rect, logical_rect) = font.glyph_extents(0 as pango::Glyph);

        unsafe {
            // Taken from https://gitlab.gnome.org/GNOME/pango/-/blob/main/pango/pango-types.h#L225
            (*font_metrics).ascent = -logical_rect.y();
            (*font_metrics).descent = logical_rect.y() + logical_rect.height();
            (*font_metrics).height = logical_rect.height();
            (*font_metrics).x_height = logical_rect.height();

            debug!(
                "Ascent: {}, descent: {}, height: {}",
                (*font_metrics).ascent,
                (*font_metrics).descent,
                (*font_metrics).height
            );
        }
    }

    #[no_mangle]
    pub extern "C" fn create_font(
        &mut self,
        face_name: *const libc::c_char,
        size: i32,
        weight: i32,
        font_metrics: *mut FontMetrics,
        options: FontOptions,
    ) -> usize {
        // @TODO underline, strikethrough, overline
        let face_name = unsafe { CStr::from_ptr(face_name) };

        let face_name = face_name.to_str().unwrap().to_string();

        if let Some(font_description_key) = self.face_name_to_font_description_key_map.get(&face_name) {
            debug!("Found font face \"{}\" with id {}", face_name, font_description_key);

            self.populate_font_metrics(font_description_key, font_metrics);

            return font_description_key.clone();
        }

        let font_description_key = self.next_font_key;
        self.next_font_key += 1;

        debug!("Created font face \"{}\" with id {}", face_name, font_description_key);

        let mut font_description = pango::FontDescription::new();
        font_description.set_family(&face_name);
        //@TODO these font descriptions seem to be size and option dependent, so the map
        //@TODO should be used to search this

        if options.intersects(FontOptions::ITALIC) {
            font_description.set_style(pango::Style::Italic);
        }

        font_description.set_size(size * pango::SCALE);

        self.font_description_map.insert(font_description_key, font_description);
        self.face_name_to_font_description_key_map.insert(face_name, font_description_key);

        self.populate_font_metrics(&font_description_key, font_metrics);

        font_description_key
    }

    #[no_mangle]
    pub extern "C" fn get_default_font_name(&self) -> *const libc::c_char {
        self.default_font.as_ptr()
    }

    #[no_mangle]
    pub extern "C" fn text_width(&self, text: *const libc::c_char, font: usize) -> i32 {
        let c_str = unsafe { CStr::from_ptr(text) };

        let text = c_str.to_str().unwrap();

        if let Some(font_description) = self.font_description_map.get(&font) {
            debug!("Font found");

            let font_map = pangocairo::FontMap::default();
            let context = font_map.create_context();

            let layout = pango::Layout::new(&context);

            layout.set_text(&text);
            layout.set_font_description(Some(&font_description));

            let (width, _) = layout.size();

            debug!("Draw text \"{}\" with width {}", text, width);

            return width;
        }

        0
    }
}
