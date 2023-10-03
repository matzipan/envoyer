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

    auto document = litehtml::document::createFromString(
        document_string, container, master_stylesheet);

    auto context = new context_struct{
        .owning_ptr = std::move(document),
    };

    return reinterpret_cast<void *>(context);
}

int render(void *context_struct_pointer, int max_width) {
    auto context = reinterpret_cast<context_struct *>(context_struct_pointer);

    context->owning_ptr->render(max_width);

    return context->owning_ptr->height();
}

void draw(void *context_struct_pointer) {
    auto context = reinterpret_cast<context_struct *>(context_struct_pointer);

    const auto clip = litehtml::position(0, 0, context->owning_ptr->width(),
                                         context->owning_ptr->height());
    context->owning_ptr->draw(reinterpret_cast<litehtml::uint_ptr>(nullptr), 0,
                              0, &clip);
}

} // namespace setup