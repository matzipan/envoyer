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
#[derive(Debug)]
pub struct WebColor {
    pub red: u8,
    pub green: u8,
    pub blue: u8,
    pub alpha: u8,
}

#[repr(C)]
#[derive(Debug)]
pub struct Position {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

#[repr(C)]
#[derive(Debug)]
pub struct FontMetrics {
    pub ascent: i32,
    pub descent: i32,
    pub height: i32,
    pub x_height: i32,
}

#[repr(C)]
#[derive(Debug)]
pub enum BackgroundAttachment {
    Fixed,
    Scroll,
}

#[repr(C)]
#[derive(Debug)]
pub enum BackgroundRepeat {
    Repeat,
    RepeatX,
    RepeatY,
    NoRepeat,
}

#[repr(C)]
#[derive(Debug)]
pub struct BorderRadiuses {
    pub top_left_x: i32,
    pub top_left_y: i32,
    pub top_right_x: i32,
    pub top_right_y: i32,
    pub bottom_right_x: i32,
    pub bottom_right_y: i32,
    pub bottom_left_x: i32,
    pub bottom_left_y: i32,
}

#[repr(C)]
#[derive(Debug)]
pub struct Size {
    pub width: i32,
    pub height: i32,
}

#[repr(C)]
#[derive(Debug)]
pub enum TextTransform {
    None,
    Capitalize,
    Uppercase,
    Lowercase,
}

#[repr(C)]
#[derive(Debug)]
pub enum MediaType {
    None,
    All,
    Screen,
    Print,
    Braille,
    Embossed,
    Handheld,
    Projection,
    Speech,
    Tty,
    Tv,
}

#[repr(C)]
#[derive(Debug)]
pub struct MediaFeatures {
    pub media_type: MediaType,
    pub width: i32,
    pub height: i32,
    pub device_width: i32,
    pub device_height: i32,
    pub color: i32,
    pub monochrome: i32,
    pub color_index: i32,
    pub resolution: i32,
}

#[repr(C)]
#[derive(Debug)]
pub struct BackgroundPaint {
    pub image: *const libc::c_char,
    pub base_url: *const libc::c_char,
    pub attachment: BackgroundAttachment,
    pub repeat: BackgroundRepeat,
    pub color: WebColor,
    pub clip_box: Position,
    pub origin_box: Position,
    pub border_box: Position,
    pub border_radiuses: BorderRadiuses,
    pub image_size: Size,
    pub position_x: i32,
    pub position_y: i32,
    pub is_root: bool,
}

#[repr(C)]
#[derive(Debug)]
pub enum ListMarkerType {
    None,
    Circle,
    Disc,
    Square,
    Armenian,
    CjkIdeographic,
    Decimal,
    DecimalLeadingZero,
    Georgian,
    Hebrew,
    Hiragana,
    HiraganaIroha,
    Katakana,
    KatakanaIroha,
    LowerAlpha,
    LowerGreek,
    LowerLatin,
    LowerRoman,
    UpperAlpha,
    UpperLatin,
    UpperRoman,
}

#[repr(C)]
#[derive(Debug)]
pub enum BorderStyle {
    None,
    Hidden,
    Dotted,
    Dashed,
    Solid,
    Double,
    Groove,
    Ridge,
    Inset,
    Outset,
}

#[repr(C)]
#[derive(Debug)]
pub struct Border {
    pub width: i32,
    pub style: BorderStyle,
    pub color: WebColor,
}

#[repr(C)]
#[derive(Debug)]
pub struct Borders {
    pub left: Border,
    pub top: Border,
    pub right: Border,
    pub bottom: Border,
    pub radiuses: BorderRadiuses,
}

#[repr(C)]
#[derive(Debug)]
pub struct ListMarker {
    pub image: *const libc::c_char,
    pub base_url: *const libc::c_char,
    pub marker_type: ListMarkerType,
    pub color: WebColor,
    pub position: Position,
}

#[repr(C)]
#[derive(Debug)]
pub struct Language {
    pub language: *const libc::c_char,
    pub culture: *const libc::c_char,
}

pub struct Callbacks {
    next_font_key: usize,
    face_name_to_font_description_key_map: std::collections::HashMap<String, usize>,
    font_description_map: std::collections::HashMap<usize, pango::FontDescription>,
    default_font: CString,
    language: CString,
    culture: CString,
    default_font_size: i64,
    render_nodes: Vec<gsk::RenderNode>,
}

impl Callbacks {
    pub fn new() -> Self {
        Self {
            next_font_key: 1,
            font_description_map: Default::default(),
            face_name_to_font_description_key_map: Default::default(),
            default_font: CString::new("DejaVu Sans").unwrap(),
            language: CString::new("en").unwrap(),
            culture: CString::new("US").unwrap(),
            default_font_size: 10,
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
    pub extern "C" fn delete_font(&mut self, font_description_key: usize) {
        let font_description = self.font_description_map.remove(&font_description_key);

        if let Some(font_description) = font_description {
            let font_family = font_description.family();

            if let Some(font_family) = font_family {
                self.face_name_to_font_description_key_map.remove(&font_family.as_str().to_owned());
            }
        }
    }

    #[no_mangle]
    pub extern "C" fn draw_text(&mut self, hdc: usize, text: *const libc::c_char, font: usize, color: WebColor, position: Position) {
        let c_str = unsafe { CStr::from_ptr(text) };

        let text = c_str.to_str().unwrap();

        if text.trim().is_empty() {
            debug!("Skipping drawing whitespace");

            return;
        } else {
            debug!("Draw text \"{}\" with font id {}", text, font);
        }

        if let Some(font_description) = self.font_description_map.get(&font) {
            debug!("Font found");

            let font_map = pangocairo::FontMap::default();
            let context = font_map.create_context();

            let font = context.load_font(font_description).unwrap();

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
        context.set_font_description(Some(font_description));

        let font = context.load_font(font_description).unwrap();

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

            return *font_description_key;
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

            layout.set_text(text);
            layout.set_font_description(Some(font_description));

            let (width, _) = layout.size();

            debug!("Draw text \"{}\" with width {}", text, width);

            return width;
        }

        0
    }

    #[no_mangle]
    pub extern "C" fn pt_to_px(&mut self, pt: i64) -> i64 {
        //@TODO

        return pt;
    }

    #[no_mangle]
    pub extern "C" fn get_default_font_size(&mut self) -> i64 {
        self.default_font_size
    }

    #[no_mangle]
    pub extern "C" fn draw_list_marker(&mut self, hdc: usize, marker: ListMarker) {
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn draw_borders(&mut self, hdc: usize, borders: Borders, draw_position: Position, root: bool) {
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn draw_background(&mut self, hdc: usize, background_paint: BackgroundPaint) {
        // The litehtml callback takes a vector of backgrounds to draw, but jsut to avoid having the complication of
        // passing vector references around, the rust draw_background is per background element

        let image = unsafe { CStr::from_ptr(background_paint.image) };
        let base_url = unsafe { CStr::from_ptr(background_paint.base_url) };

        debug!("Draw background {:?} image {:?} base_url {:?}", background_paint, image, base_url);

        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn load_image(&mut self, src: *const libc::c_char, base_url: *const libc::c_char, redraw_on_ready: bool) {
        let src = unsafe { CStr::from_ptr(src) };
        let base_url = unsafe { CStr::from_ptr(base_url) };
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn get_image_size(&mut self, src: *const libc::c_char, base_url: *const libc::c_char) -> Size {
        let src = unsafe { CStr::from_ptr(src) };
        let base_url = unsafe { CStr::from_ptr(base_url) };

        //@TODO
        Size { height: 1, width: 1 }
    }

    #[no_mangle]
    pub extern "C" fn set_caption(&mut self, caption: *const libc::c_char) {
        //@TODO
        let caption = unsafe { CStr::from_ptr(caption) };
    }

    #[no_mangle]
    pub extern "C" fn set_base_url(&mut self, base_url: *const libc::c_char) {
        //@TODO
        let base_url = unsafe { CStr::from_ptr(base_url) };
    }

    #[no_mangle]
    pub extern "C" fn set_cursor(&mut self, cursor: *const libc::c_char) {
        //@TODO
        let cursor = unsafe { CStr::from_ptr(cursor) };
    }

    #[no_mangle]
    pub extern "C" fn transform_text(&mut self, text: *const libc::c_char, text_transform: TextTransform) {
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn import_css(&mut self, text: *const libc::c_char, url: *const libc::c_char, base_url: *const libc::c_char) {
        let text = unsafe { CStr::from_ptr(text) };
        let url = unsafe { CStr::from_ptr(url) };
        let base_url = unsafe { CStr::from_ptr(base_url) };
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn set_clip(&mut self, position: Position, borders: BorderRadiuses) {
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn del_clip(&mut self) {
        //@TODO
    }

    #[no_mangle]
    pub extern "C" fn get_client_rect(&mut self) -> Position {
        //@TODO
        Position {
            x: 0,
            y: 0,
            width: 0,
            height: 0,
        }
    }

    #[no_mangle]
    pub extern "C" fn get_language(&self) -> Language {
        Language {
            language: self.language.as_ptr(),
            culture: self.culture.as_ptr(),
        }
    }

    #[no_mangle]
    pub extern "C" fn get_media_features(&mut self) -> MediaFeatures {
        let client_rect = self.get_client_rect();

        //@TODO
        MediaFeatures {
            media_type: MediaType::Screen,
            width: client_rect.width,
            height: client_rect.height,
            device_width: 0,
            device_height: 0,
            color: 8,
            monochrome: 0,
            color_index: 256,
            resolution: 96,
        }
    }
}
