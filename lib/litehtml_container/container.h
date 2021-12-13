#pragma once

#include <litehtml/litehtml.h>

class litehtml_container : public litehtml::document_container {
    void * instance;

  public:
    litehtml_container(void* instance);

    virtual ~litehtml_container(void);

    virtual litehtml::uint_ptr create_font(const litehtml::tchar_t *face_name,
                                           int size, int weight,
                                           litehtml::font_style italic,
                                           unsigned int decoration,
                                           litehtml::font_metrics *metrics);
    virtual void delete_font(litehtml::uint_ptr font);
    virtual int text_width(const litehtml::tchar_t *text,
                           litehtml::uint_ptr font);
    virtual void draw_text(litehtml::uint_ptr hdc,
                           const litehtml::tchar_t *text,
                           litehtml::uint_ptr font, litehtml::web_color color,
                           const litehtml::position &position);
    virtual int pt_to_px(int pt);
    virtual int get_default_font_size() const;
    virtual const litehtml::tchar_t *get_default_font_name() const;
    virtual void draw_list_marker(litehtml::uint_ptr hdc,
                                  const litehtml::list_marker &marker);
    virtual void load_image(const litehtml::tchar_t *src,
                            const litehtml::tchar_t *base_url,
                            bool redraw_on_ready);
    virtual void get_image_size(const litehtml::tchar_t *src,
                                const litehtml::tchar_t *base_url,
                                litehtml::size &sz);
    virtual void draw_background(litehtml::uint_ptr hdc,
                                 const litehtml::background_paint &bg);
    virtual void draw_borders(litehtml::uint_ptr hdc,
                              const litehtml::borders &borders,
                              const litehtml::position &draw_position, bool root);

    virtual void set_caption(const litehtml::tchar_t *caption);
    virtual void set_base_url(const litehtml::tchar_t *base_url);
    virtual void link(const std::shared_ptr<litehtml::document> &doc,
                      const litehtml::element::ptr &el);
    virtual void on_anchor_click(const litehtml::tchar_t *url,
                                 const litehtml::element::ptr &el);
    virtual void set_cursor(const litehtml::tchar_t *cursor);
    virtual void transform_text(litehtml::tstring &text,
                                litehtml::text_transform text_transform);
    virtual void import_css(litehtml::tstring &text,
                            const litehtml::tstring &url,
                            litehtml::tstring &base_url);
    virtual void set_clip(const litehtml::position &position,
                          const litehtml::border_radiuses &bdr_radius,
                          bool valid_x, bool valid_y);
    virtual void del_clip();
    virtual void get_client_rect(litehtml::position &client) const;
    virtual std::shared_ptr<litehtml::element>
    create_element(const litehtml::tchar_t *tag_name,
                   const litehtml::string_map &attributes,
                   const std::shared_ptr<litehtml::document> &doc);

    virtual void get_media_features(litehtml::media_features &media) const;
    virtual void get_language(litehtml::tstring &language,
                              litehtml::tstring &culture) const;
    virtual int
    get_text_offset_of_mouse_pointer(const litehtml::position &mouse_position,
                                     const litehtml::tchar_t *text,
                                     litehtml::uint_ptr font);
    virtual litehtml::tstring
    resolve_color(const litehtml::tstring &color) const;
};
