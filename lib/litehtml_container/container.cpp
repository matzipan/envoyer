#include "container.h"
#include "litehtml_rust.hpp"

#include <iostream>

litehtml_container::litehtml_container(void *instance) : instance{instance} {}

litehtml_container::~litehtml_container(void) {}

void litehtml_container::draw_text(litehtml::uint_ptr hdc,
                                   const litehtml::tchar_t *text,
                                   litehtml::uint_ptr font,
                                   litehtml::web_color color,
                                   const litehtml::position &position) {
    litehtml_rust::WebColor rust_color{
        .red = color.red,
        .green = color.green,
        .blue = color.blue,
        .alpha = color.alpha,
    };

    litehtml_rust::Position rust_position{
        .x = position.x,
        .y = position.y,
        .width = position.width,
        .height = position.height,
    };

    litehtml_rust::draw_text(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), hdc, text, font,
        rust_color, rust_position);
}

std::shared_ptr<litehtml::element> litehtml_container::create_element(
    const litehtml::tchar_t *tag_name, const litehtml::string_map &attributes,
    const std::shared_ptr<litehtml::document> &doc) {
    return 0;
}

litehtml::uint_ptr
litehtml_container::create_font(const litehtml::tchar_t *face_name, int size,
                                int weight, litehtml::font_style italic,
                                unsigned int decoration,
                                litehtml::font_metrics *metrics) {
    litehtml_rust::FontOptions font_options;

    if (italic == litehtml::fontStyleItalic) {
        font_options |= litehtml_rust::FontOptions_ITALIC;
    }

    if (decoration & litehtml::font_decoration_linethrough) {
        font_options |= litehtml_rust::FontOptions_LINETHROUGH;
    }

    if (decoration & litehtml::font_decoration_underline) {
        font_options |= litehtml_rust::FontOptions_UNDERLINE;
    }

    if (decoration & litehtml::font_decoration_overline) {
        font_options |= litehtml_rust::FontOptions_OVERLINE;
    }

    litehtml_rust::FontMetrics rust_metrics;

    auto font = litehtml_rust::create_font(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), face_name, size,
        weight, &rust_metrics, font_options);

    metrics->ascent = rust_metrics.ascent;
    metrics->descent = rust_metrics.descent;
    metrics->height = rust_metrics.height;
    metrics->x_height = rust_metrics.x_height;

    return font;
}
void litehtml_container::delete_font(litehtml::uint_ptr font) {}
int litehtml_container::text_width(const litehtml::tchar_t *text,
                                   litehtml::uint_ptr font) {

    return litehtml_rust::text_width(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), text, font);
}
int litehtml_container::pt_to_px(int pt) { return pt; }
int litehtml_container::get_default_font_size() const { return 10; }
const litehtml::tchar_t *litehtml_container::get_default_font_name() const {
    return litehtml_rust::get_default_font_name(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));
}
void litehtml_container::draw_list_marker(litehtml::uint_ptr hdc,
                                          const litehtml::list_marker &marker) {
}
void litehtml_container::load_image(const litehtml::tchar_t *src,
                                    const litehtml::tchar_t *base_url,
                                    bool redraw_on_ready) {}
void litehtml_container::get_image_size(const litehtml::tchar_t *src,
                                        const litehtml::tchar_t *base_url,
                                        litehtml::size &sz) {}
void litehtml_container::draw_background(litehtml::uint_ptr hdc,
                                         const litehtml::background_paint &bg) {
}
void litehtml_container::draw_borders(litehtml::uint_ptr hdc,
                                      const litehtml::borders &borders,
                                      const litehtml::position &draw_position,
                                      bool root) {}

void litehtml_container::set_caption(const litehtml::tchar_t *caption) {}
void litehtml_container::set_base_url(const litehtml::tchar_t *base_url) {}
void litehtml_container::link(const std::shared_ptr<litehtml::document> &doc,
                              const litehtml::element::ptr &el) {}
void litehtml_container::on_anchor_click(const litehtml::tchar_t *url,
                                         const litehtml::element::ptr &el) {}
void litehtml_container::set_cursor(const litehtml::tchar_t *cursor) {}
void litehtml_container::transform_text(
    litehtml::tstring &text, litehtml::text_transform text_transform) {}
void litehtml_container::import_css(litehtml::tstring &text,
                                    const litehtml::tstring &url,
                                    litehtml::tstring &base_url) {}
void litehtml_container::set_clip(const litehtml::position &position,
                                  const litehtml::border_radiuses &bdr_radius,
                                  bool valid_x, bool valid_y) {}
void litehtml_container::del_clip() {}
void litehtml_container::get_client_rect(litehtml::position &client) const {}
void litehtml_container::get_media_features(
    litehtml::media_features &media) const {}
void litehtml_container::get_language(litehtml::tstring &language,
                                      litehtml::tstring &culture) const {}
int litehtml_container::get_text_offset_of_mouse_pointer(
    const litehtml::position &mouse_position, const litehtml::tchar_t *text,
    litehtml::uint_ptr font) {
    return 0;
}
litehtml::tstring
litehtml_container::resolve_color(const litehtml::tstring &color) const {
    return litehtml::tstring();
}