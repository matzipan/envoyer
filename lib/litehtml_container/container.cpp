#include "container.h"

litehtml_container::litehtml_container(void (*draw_text_func)())
    : draw_text_func{draw_text_func} {}

litehtml_container::~litehtml_container(void) {}

litehtml::uint_ptr
litehtml_container::create_font(const litehtml::tchar_t *faceName, int size,
                                int weight, litehtml::font_style italic,
                                unsigned int decoration,
                                litehtml::font_metrics *fm) {}

void litehtml_container::delete_font(litehtml::uint_ptr hFont) {}

int litehtml_container::text_width(const litehtml::tchar_t *text,
                                   litehtml::uint_ptr hFont) {}

void litehtml_container::draw_text(litehtml::uint_ptr hdc,
                                   const litehtml::tchar_t *text,
                                   litehtml::uint_ptr hFont,
                                   litehtml::web_color color,
                                   const litehtml::position &pos) {
  draw_text_func();
}

int litehtml_container::pt_to_px(int pt) {}

int litehtml_container::get_default_font_size() const {}

void litehtml_container::draw_list_marker(litehtml::uint_ptr hdc,
                                          const litehtml::list_marker &marker) {
}

void litehtml_container::load_image(const litehtml::tchar_t *src,
                                    const litehtml::tchar_t *baseurl,
                                    bool redraw_on_ready) {}

void litehtml_container::get_image_size(const litehtml::tchar_t *src,
                                        const litehtml::tchar_t *baseurl,
                                        litehtml::size &sz) {}

void litehtml_container::draw_background(litehtml::uint_ptr hdc,
                                         const litehtml::background_paint &bg) {
}

void litehtml_container::make_url(const litehtml::tchar_t *url,
                                  const litehtml::tchar_t *basepath,
                                  litehtml::tstring &out) {}

void litehtml_container::add_path_arc(void *pointer, double x, double y,
                                      double rx, double ry, double a1,
                                      double a2, bool neg) {}

void litehtml_container::draw_borders(litehtml::uint_ptr hdc,
                                      const litehtml::borders &borders,
                                      const litehtml::position &draw_pos,
                                      bool root) {}

void litehtml_container::transform_text(litehtml::tstring &text,
                                        litehtml::text_transform tt) {}

void litehtml_container::set_clip(const litehtml::position &pos,
                                  const litehtml::border_radiuses &bdr_radius,
                                  bool valid_x, bool valid_y) {}

void litehtml_container::del_clip() {}

void litehtml_container::apply_clip(void *pointer) {}

void litehtml_container::draw_ellipse(void *pointer, int x, int y, int width,
                                      int height,
                                      const litehtml::web_color &color,
                                      int line_width) {}

void litehtml_container::fill_ellipse(void *pointer, int x, int y, int width,
                                      int height,
                                      const litehtml::web_color &color) {}

const litehtml::tchar_t *litehtml_container::get_default_font_name() const {}

std::shared_ptr<litehtml::element> litehtml_container::create_element(
    const litehtml::tchar_t *tag_name, const litehtml::string_map &attributes,
    const std::shared_ptr<litehtml::document> &doc) {}

void litehtml_container::rounded_rectangle(
    void *pointer, const litehtml::position &pos,
    const litehtml::border_radiuses &radius) {}

void litehtml_container::draw_pixbuf(void *pointer,
                                     const litehtml::uint_ptr bmp, int x, int y,
                                     int cx, int cy) {}

void *litehtml_container::surface_from_pixbuf(const litehtml::uint_ptr bmp) {}

void litehtml_container::get_media_features(
    litehtml::media_features &media) const {}

void litehtml_container::get_language(litehtml::tstring &language,
                                      litehtml::tstring &culture) const {}

void litehtml_container::link(const std::shared_ptr<litehtml::document> &ptr,
                              const litehtml::element::ptr &el) {}

int litehtml_container::get_text_offset_of_mouse_pointer(
    const litehtml::position &mouse_position, const litehtml::tchar_t *text,
    litehtml::uint_ptr hFont) {}