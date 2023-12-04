#include "container.h"
#include "litehtml_rust.hpp"

#include <iostream>

litehtml_container::litehtml_container(void *instance) : instance{instance} {}

litehtml_container::~litehtml_container(void) {}

litehtml_rust::WebColor convert_color(const litehtml::web_color &color) {
    litehtml_rust::WebColor rust_color{
        .red = color.red,
        .green = color.green,
        .blue = color.blue,
        .alpha = color.alpha,
    };

    return rust_color;
}

litehtml_rust::Position convert_position(const litehtml::position &position) {
    litehtml_rust::Position rust_position{
        .x = position.x,
        .y = position.y,
        .width = position.width,
        .height = position.height,
    };

    return rust_position;
}

litehtml_rust::BorderRadiuses
convert_border_radiuses(const litehtml::border_radiuses &border_radiuses) {
    litehtml_rust::BorderRadiuses rust_border_radiuses{
        .top_left_x = border_radiuses.top_left_x,
        .top_left_y = border_radiuses.top_left_y,
        .top_right_x = border_radiuses.top_right_x,
        .top_right_y = border_radiuses.top_right_y,
        .bottom_right_x = border_radiuses.bottom_right_x,
        .bottom_right_y = border_radiuses.bottom_right_y,
        .bottom_left_x = border_radiuses.bottom_left_x,
        .bottom_left_y = border_radiuses.bottom_left_y,
    };

    return rust_border_radiuses;
}

void litehtml_container::draw_text(litehtml::uint_ptr hdc, const char *text,
                                   litehtml::uint_ptr font,
                                   litehtml::web_color color,
                                   const litehtml::position &position) {

    litehtml_rust::WebColor rust_color = convert_color(color);
    litehtml_rust::Position rust_position = convert_position(position);

    litehtml_rust::draw_text(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), hdc, text, font,
        rust_color, rust_position);
}

std::shared_ptr<litehtml::element> litehtml_container::create_element(
    const char *tag_name, const litehtml::string_map &attributes,
    const std::shared_ptr<litehtml::document> &doc) {
    return 0;
}

litehtml::uint_ptr litehtml_container::create_font(
    const char *face_name, int size, int weight, litehtml::font_style italic,
    unsigned int decoration, litehtml::font_metrics *metrics) {
    litehtml_rust::FontOptions font_options;

    if (italic == litehtml::font_style_italic) {
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

void litehtml_container::delete_font(litehtml::uint_ptr font) {
    litehtml_rust::delete_font(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), font);
}

int litehtml_container::text_width(const char *text, litehtml::uint_ptr font) {
    return litehtml_rust::text_width(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), text, font);
}

int litehtml_container::pt_to_px(int pt) const {
    return litehtml_rust::pt_to_px(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), pt);
}

int litehtml_container::get_default_font_size() const {
    return litehtml_rust::get_default_font_size(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));
}

const char *litehtml_container::get_default_font_name() const {
    return litehtml_rust::get_default_font_name(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));
}

litehtml_rust::BackgroundRepeat
convert_background_repeat(const litehtml::background_repeat &repeat) {
    if (repeat == litehtml::background_repeat_repeat) {
        return litehtml_rust::BackgroundRepeat::Repeat;
    }

    if (repeat == litehtml::background_repeat_repeat_x) {
        return litehtml_rust::BackgroundRepeat::RepeatX;
    }

    if (repeat == litehtml::background_repeat_repeat_y) {
        return litehtml_rust::BackgroundRepeat::RepeatY;
    }

    if (repeat == litehtml::background_repeat_no_repeat) {
        return litehtml_rust::BackgroundRepeat::NoRepeat;
    }

    // This should not happen, but just in case
    return litehtml_rust::BackgroundRepeat::Repeat;
}

litehtml_rust::BackgroundAttachment convert_background_attachment(
    const litehtml::background_attachment &attachment) {
    if (attachment == litehtml::background_attachment_fixed) {
        return litehtml_rust::BackgroundAttachment::Fixed;
    }

    if (attachment == litehtml::background_attachment_scroll) {
        return litehtml_rust::BackgroundAttachment::Scroll;
    }

    // This should not happen, but just in case
    return litehtml_rust::BackgroundAttachment::Scroll;
}

void litehtml_container::draw_background(
    litehtml::uint_ptr hdc, const std::vector<litehtml::background_paint> &bg) {

    for (const auto &background_paint : bg) {
        litehtml_rust::BackgroundPaint rust_background_paint;

        rust_background_paint.image = background_paint.image.c_str();
        rust_background_paint.base_url = background_paint.baseurl.c_str();

        rust_background_paint.repeat =
            convert_background_repeat(background_paint.repeat);

        rust_background_paint.attachment =
            convert_background_attachment(background_paint.attachment);

        rust_background_paint.color = convert_color(background_paint.color);

        rust_background_paint.clip_box =
            convert_position(background_paint.clip_box);

        rust_background_paint.origin_box =
            convert_position(background_paint.origin_box);

        rust_background_paint.border_box =
            convert_position(background_paint.border_box);

        rust_background_paint.border_radiuses =
            convert_border_radiuses(background_paint.border_radius);

        litehtml_rust::Size image_size{
            .width = background_paint.image_size.width,
            .height = background_paint.image_size.height,
        };

        rust_background_paint.image_size = image_size;

        rust_background_paint.position_x = background_paint.position_x;
        rust_background_paint.position_y = background_paint.position_y;
        rust_background_paint.is_root = background_paint.is_root;

        litehtml_rust::draw_background(
            reinterpret_cast<litehtml_rust::Callbacks *>(instance), hdc,
            rust_background_paint);
    }
}

litehtml_rust::ListMarkerType
convert_marker_type(const litehtml::list_style_type &marker_type) {
    if (marker_type == litehtml::list_style_type_none) {
        return litehtml_rust::ListMarkerType::None;
    }

    if (marker_type == litehtml::list_style_type_circle) {
        return litehtml_rust::ListMarkerType::Circle;
    }

    if (marker_type == litehtml::list_style_type_disc) {
        return litehtml_rust::ListMarkerType::Disc;
    }

    if (marker_type == litehtml::list_style_type_square) {
        return litehtml_rust::ListMarkerType::Square;
    }

    if (marker_type == litehtml::list_style_type_armenian) {
        return litehtml_rust::ListMarkerType::Armenian;
    }

    if (marker_type == litehtml::list_style_type_cjk_ideographic) {
        return litehtml_rust::ListMarkerType::CjkIdeographic;
    }

    if (marker_type == litehtml::list_style_type_decimal) {
        return litehtml_rust::ListMarkerType::Decimal;
    }

    if (marker_type == litehtml::list_style_type_decimal_leading_zero) {
        return litehtml_rust::ListMarkerType::DecimalLeadingZero;
    }

    if (marker_type == litehtml::list_style_type_georgian) {
        return litehtml_rust::ListMarkerType::Georgian;
    }

    if (marker_type == litehtml::list_style_type_hebrew) {
        return litehtml_rust::ListMarkerType::Hebrew;
    }

    if (marker_type == litehtml::list_style_type_hiragana) {
        return litehtml_rust::ListMarkerType::Hiragana;
    }

    if (marker_type == litehtml::list_style_type_hiragana_iroha) {
        return litehtml_rust::ListMarkerType::HiraganaIroha;
    }

    if (marker_type == litehtml::list_style_type_katakana) {
        return litehtml_rust::ListMarkerType::Katakana;
    }

    if (marker_type == litehtml::list_style_type_katakana_iroha) {
        return litehtml_rust::ListMarkerType::KatakanaIroha;
    }

    if (marker_type == litehtml::list_style_type_lower_alpha) {
        return litehtml_rust::ListMarkerType::LowerAlpha;
    }

    if (marker_type == litehtml::list_style_type_lower_greek) {
        return litehtml_rust::ListMarkerType::LowerGreek;
    }

    if (marker_type == litehtml::list_style_type_lower_latin) {
        return litehtml_rust::ListMarkerType::LowerLatin;
    }

    if (marker_type == litehtml::list_style_type_lower_roman) {
        return litehtml_rust::ListMarkerType::LowerRoman;
    }

    if (marker_type == litehtml::list_style_type_upper_alpha) {
        return litehtml_rust::ListMarkerType::UpperAlpha;
    }

    if (marker_type == litehtml::list_style_type_upper_latin) {
        return litehtml_rust::ListMarkerType::UpperLatin;
    }

    if (marker_type == litehtml::list_style_type_upper_roman) {
        return litehtml_rust::ListMarkerType::UpperRoman;
    }

    // This should not happen, but just in case
    return litehtml_rust::ListMarkerType::Disc;
}

void litehtml_container::draw_list_marker(litehtml::uint_ptr hdc,
                                          const litehtml::list_marker &marker) {

    litehtml_rust::ListMarker rust_marker;

    rust_marker.image = marker.image.c_str();
    rust_marker.base_url = marker.baseurl;
    rust_marker.marker_type = convert_marker_type(marker.marker_type);
    rust_marker.color = convert_color(marker.color);
    rust_marker.position = convert_position(marker.pos);

    litehtml_rust::draw_list_marker(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), hdc,
        rust_marker);
}

litehtml_rust::BorderStyle
convert_border_style(const litehtml::border_style &border_style) {

    if (border_style == litehtml::border_style_none) {
        return litehtml_rust::BorderStyle::None;
    }

    if (border_style == litehtml::border_style_hidden) {
        return litehtml_rust::BorderStyle::Hidden;
    }

    if (border_style == litehtml::border_style_dotted) {
        return litehtml_rust::BorderStyle::Dotted;
    }

    if (border_style == litehtml::border_style_dashed) {
        return litehtml_rust::BorderStyle::Dashed;
    }

    if (border_style == litehtml::border_style_solid) {
        return litehtml_rust::BorderStyle::Solid;
    }

    if (border_style == litehtml::border_style_double) {
        return litehtml_rust::BorderStyle::Double;
    }

    if (border_style == litehtml::border_style_groove) {
        return litehtml_rust::BorderStyle::Groove;
    }

    if (border_style == litehtml::border_style_ridge) {
        return litehtml_rust::BorderStyle::Ridge;
    }

    if (border_style == litehtml::border_style_inset) {
        return litehtml_rust::BorderStyle::Inset;
    }

    if (border_style == litehtml::border_style_outset) {
        return litehtml_rust::BorderStyle::Outset;
    }

    // This should not happen, but just in case
    return litehtml_rust::BorderStyle::Solid;
}

litehtml_rust::Border convert_border(const litehtml::border &border) {

    litehtml_rust::Border rust_border{
        .width = border.width,
        .style = convert_border_style(border.style),
        .color = convert_color(border.color),

    };

    return rust_border;
}

litehtml_rust::Borders convert_borders(const litehtml::borders &borders) {
    litehtml_rust::Borders rust_borders{
        .left = convert_border(borders.left),
        .top = convert_border(borders.top),
        .right = convert_border(borders.right),
        .bottom = convert_border(borders.bottom),
        .radiuses = convert_border_radiuses(borders.radius),
    };

    return rust_borders;
}

void litehtml_container::draw_borders(litehtml::uint_ptr hdc,
                                      const litehtml::borders &borders,
                                      const litehtml::position &draw_position,
                                      bool root) {

    litehtml_rust::Position rust_draw_position =
        convert_position(draw_position);
    litehtml_rust::Borders rust_borders = convert_borders(borders);

    litehtml_rust::draw_borders(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), hdc,
        rust_borders, rust_draw_position, root);
}

void litehtml_container::load_image(const char *src, const char *base_url,
                                    bool redraw_on_ready) {
    litehtml_rust::load_image(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), src, base_url,
        redraw_on_ready);
}

void litehtml_container::get_image_size(const char *src, const char *base_url,
                                        litehtml::size &sz) {
    auto rust_size = litehtml_rust::get_image_size(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), src, base_url);

    sz.width = rust_size.width;
    sz.height = rust_size.height;
}

void litehtml_container::set_caption(const char *caption) {
    litehtml_rust::set_caption(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), caption);
}

void litehtml_container::set_base_url(const char *base_url) {
    litehtml_rust::set_base_url(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), base_url);
}

void litehtml_container::set_cursor(const char *cursor) {
    litehtml_rust::set_cursor(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), cursor);
}

litehtml_rust::TextTransform
convert_text_transform(const litehtml::text_transform text_transform) {
    if (text_transform == litehtml::text_transform_none) {
        return litehtml_rust::TextTransform::None;
    }

    if (text_transform == litehtml::text_transform_capitalize) {
        return litehtml_rust::TextTransform::Capitalize;
    }

    if (text_transform == litehtml::text_transform_uppercase) {
        return litehtml_rust::TextTransform::Uppercase;
    }

    if (text_transform == litehtml::text_transform_lowercase) {
        return litehtml_rust::TextTransform::Lowercase;
    }

    // This should not happen, but just in case
    return litehtml_rust::TextTransform::None;
}

void litehtml_container::transform_text(
    litehtml::string &text, litehtml::text_transform text_transform) {

    auto rust_text_transform = convert_text_transform(text_transform);

    litehtml_rust::transform_text(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), text.c_str(),
        rust_text_transform);
}
void litehtml_container::import_css(litehtml::string &text,
                                    const litehtml::string &url,
                                    litehtml::string &base_url) {
    litehtml_rust::import_css(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), text.c_str(),
        url.c_str(), base_url.c_str());
}
void litehtml_container::set_clip(
    const litehtml::position &pos,
    const litehtml::border_radiuses &border_radius) {

    auto rust_position = convert_position(pos);
    auto rust_border_radiuses = convert_border_radiuses(border_radius);

    litehtml_rust::set_clip(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance), rust_position,
        rust_border_radiuses);
}
void litehtml_container::del_clip() {
    litehtml_rust::del_clip(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));
}
void litehtml_container::get_client_rect(
    litehtml::position &client_rect) const {
    auto rust_client_rect = litehtml_rust::get_client_rect(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));

    client_rect.x = rust_client_rect.x;
    client_rect.y = rust_client_rect.y;
    client_rect.width = rust_client_rect.width;
    client_rect.height = rust_client_rect.height;
}

litehtml::media_type
convert_rust_media_type(litehtml_rust::MediaType &media_type) {
    if (media_type == litehtml_rust::MediaType::None) {
        return litehtml::media_type::media_type_none;
    }

    if (media_type == litehtml_rust::MediaType::All) {
        return litehtml::media_type::media_type_all;
    }

    if (media_type == litehtml_rust::MediaType::Screen) {
        return litehtml::media_type::media_type_screen;
    }

    if (media_type == litehtml_rust::MediaType::Print) {
        return litehtml::media_type::media_type_print;
    }

    if (media_type == litehtml_rust::MediaType::Braille) {
        return litehtml::media_type::media_type_braille;
    }

    if (media_type == litehtml_rust::MediaType::Embossed) {
        return litehtml::media_type::media_type_embossed;
    }

    if (media_type == litehtml_rust::MediaType::Handheld) {
        return litehtml::media_type::media_type_handheld;
    }

    if (media_type == litehtml_rust::MediaType::Projection) {
        return litehtml::media_type::media_type_projection;
    }

    if (media_type == litehtml_rust::MediaType::Speech) {
        return litehtml::media_type::media_type_speech;
    }

    if (media_type == litehtml_rust::MediaType::Tty) {
        return litehtml::media_type::media_type_tty;
    }

    if (media_type == litehtml_rust::MediaType::Tv) {
        return litehtml::media_type::media_type_tv;
    }

    // This should not happen, but just in case
    return litehtml::media_type::media_type_none;
}

void litehtml_container::get_media_features(
    litehtml::media_features &media_features) const {
    auto rust_media_features = litehtml_rust::get_media_features(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));

    media_features.type =
        convert_rust_media_type(rust_media_features.media_type);
    media_features.width = rust_media_features.width;
    media_features.height = rust_media_features.height;
    media_features.device_width = rust_media_features.device_width;
    media_features.device_height = rust_media_features.device_height;
    media_features.color = rust_media_features.color;
    media_features.monochrome = rust_media_features.monochrome;
    media_features.color_index = rust_media_features.color_index;
    media_features.resolution = rust_media_features.resolution;
}

void litehtml_container::get_language(litehtml::string &language,
                                      litehtml::string &culture) const {
    auto rust_language = litehtml_rust::get_language(
        reinterpret_cast<litehtml_rust::Callbacks *>(instance));

    language = rust_language.language;
    culture = rust_language.culture;
}

int litehtml_container::get_text_offset_of_mouse_pointer(
    const litehtml::position &mouse_position, const char *text,
    litehtml::uint_ptr font) {
    return 0;
}

void litehtml_container::link(const std::shared_ptr<litehtml::document> &doc,
                              const litehtml::element::ptr &el) {
    //@TODO add ticket for later
}

void litehtml_container::on_anchor_click(const char *url,
                                         const litehtml::element::ptr &el) {
    //@TODO add ticket for later
}

litehtml::string
litehtml_container::resolve_color(const litehtml::string &color) const {

    //@TODO add ticket for later
    return litehtml::string();
}