#include "setup.h"
#include "container.h"
#include "litehtml_rust.hpp"
#include <litehtml/litehtml.h>

#include <iostream>

#define PANGO_SCALE 1024

namespace setup {

void *setup_litehtml(const char *master_stylesheet, const char *document_string,
                     void *callbacks_instance) {
    litehtml_container *container = new litehtml_container(callbacks_instance);

    litehtml::context *litehtml_context = new litehtml::context();

    litehtml_context->load_master_stylesheet(master_stylesheet);

    auto document = litehtml::document::createFromString(
        document_string, container, litehtml_context);

    bla *x = new bla{
        .owning_ptr = std::move(document),
    };

    return reinterpret_cast<void *>(x);
}

int render(void *bla_pointer, int max_width) {
    auto x = reinterpret_cast<bla *>(bla_pointer);

    x->owning_ptr->render(max_width);

    return x->owning_ptr->height();
}

void draw(void *bla_pointer) {
    auto x = reinterpret_cast<bla *>(bla_pointer);

    const auto clip = litehtml::position(0, 0, x->owning_ptr->width(),
                                         x->owning_ptr->height());
    x->owning_ptr->draw(reinterpret_cast<litehtml::uint_ptr>(nullptr), 0, 0,
                        &clip);
}

} // namespace setup