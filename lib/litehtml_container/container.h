#pragma once

#include <litehtml/litehtml.h>

class litehtml_container : public litehtml::document_container {
    void *instance;

  public:
    litehtml_container(void *instance);

    virtual ~litehtml_container(void);

    virtual litehtml::uint_ptr create_font(const char *face_name, int size,
                                           int weight,
                                           litehtml::font_style italic,
                                           unsigned int decoration,
                                           litehtml::font_metrics *metrics);
    virtual void delete_font(litehtml::uint_ptr font);
    virtual int text_width(const char *text, litehtml::uint_ptr font);
    virtual void draw_text(litehtml::uint_ptr hdc, const char *text,
                           litehtml::uint_ptr font, litehtml::web_color color,
                           const litehtml::position &position);
    virtual int pt_to_px(int pt) const;
    virtual int get_default_font_size() const;
    virtual const char *get_default_font_name() const;
    virtual void draw_list_marker(litehtml::uint_ptr hdc,
                                  const litehtml::list_marker &marker);
    virtual void load_image(const char *src, const char *base_url,
                            bool redraw_on_ready);
    virtual void get_image_size(const char *src, const char *base_url,
                                litehtml::size &sz);
    virtual void
    draw_background(litehtml::uint_ptr hdc,
                    const std::vector<litehtml::background_paint> &bg);
    virtual void draw_borders(litehtml::uint_ptr hdc,
                              const litehtml::borders &borders,
                              const litehtml::position &draw_position,
                              bool root);

    virtual void set_caption(const char *caption);
    virtual void set_base_url(const char *base_url);
    virtual void link(const std::shared_ptr<litehtml::document> &doc,
                      const litehtml::element::ptr &el);
    virtual void on_anchor_click(const char *url,
                                 const litehtml::element::ptr &el);
    virtual void set_cursor(const char *cursor);
    virtual void transform_text(litehtml::string &text,
                                litehtml::text_transform text_transform);
    virtual void import_css(litehtml::string &text, const litehtml::string &url,
                            litehtml::string &base_url);
    virtual void set_clip(const litehtml::position &pos,
                          const litehtml::border_radiuses &bdr_radius);
    virtual void del_clip();
    virtual void get_client_rect(litehtml::position &client) const;
    virtual std::shared_ptr<litehtml::element>
    create_element(const char *tag_name, const litehtml::string_map &attributes,
                   const std::shared_ptr<litehtml::document> &doc);

    virtual void get_media_features(litehtml::media_features &media) const;
    virtual void get_language(litehtml::string &language,
                              litehtml::string &culture) const;
    virtual int
    get_text_offset_of_mouse_pointer(const litehtml::position &mouse_position,
                                     const char *text, litehtml::uint_ptr font);
    virtual litehtml::string resolve_color(const litehtml::string &color) const;
};
