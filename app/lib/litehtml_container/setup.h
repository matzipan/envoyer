#pragma once

#include <litehtml/litehtml.h>
#include <memory>

namespace setup {

struct context_struct {
    std::shared_ptr<litehtml::document> owning_ptr;
};

void *setup_litehtml(const char *master_stylesheet, const char *document_string,
                     void *callbacks_instance);

int render(void *bla_pointer, int max_width);

void draw(void *bla_pointer);

} // namespace setup