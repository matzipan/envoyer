async void foo () throws GLib.Error {
    E.SourceRegistry registry = yield new E.SourceRegistry (null); 
    
    registry.debug_dump(null);
}
void main() {
    var loop = new MainLoop ();
    foo.begin ((obj, res) => {
        try {
            foo.end ();    
        } catch(GLib.Error e) {
            message("exception encountered, %s", e.message);
        }
        loop.quit ();
    });
    loop.run (); 
}
/*
async void foo () throws GLib.Error {
    E.SourceRegistry registry = yield new E.SourceRegistry (null); 
    
    registry.debug_dump(null);
}
int main(string[] args) {
    try {
        foo.begin();
        
        /*sourceRegistry.debug_dump(null);
        
        var sourceList = sourceRegistry.list_sources(null);
        
        foreach(var source in sourceList) {
            message(source.get_display_name());
        }
        
        var scratch = new E.Source.with_uid("bla", null);
        if(scratch.has_extension(E.SOURCE_EXTENSION_GOA)) {
            message("GOA found");
        }
        if(scratch.has_extension(E.SOURCE_EXTENSION_ADDRESS_BOOK)) {
            message("Address book found");
        }
        var local = scratch.get_extension(E.SOURCE_EXTENSION_ADDRESS_BOOK);
        var client = E.BookClient.connect_sync(scratch, 5, null);
    } catch(GLib.Error e) {
        message("exception encountered, %s", e.message);
    }
    
    
    return 0;
}
*/
