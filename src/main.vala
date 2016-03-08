async void foo () throws GLib.Error {
    E.SourceRegistry registry = yield new E.SourceRegistry (null); 
    
    registry.debug_dump(null);
    
    var sourceList = registry.list_sources(null);
    
    var providerList = Camel.Provider.list(true);
    
    foreach(var source in sourceList) {
        message(source.get_display_name());
        
        if(source.has_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT)) {
            message("MAIL found");
        }
        
        foreach(var provider in providerList) {
            if(source.has_extension(E.SourceCamel.get_extension_name(provider.protocol))) {
                message("CAMEL %s found", provider.protocol);
            }
        }


        if(source.has_extension(E.SOURCE_EXTENSION_UOA)) {
            message("UOA found");
        }
        if(source.has_extension(E.SOURCE_EXTENSION_ADDRESS_BOOK)) {
            message("Address book found");
        }
    }
}
void main() {
    var loop = new MainLoop ();
    foo.begin ((obj, res) => {
        try {
            foo.end (res);    
        } catch(GLib.Error e) {
            message("exception encountered, %s", e.message);
        }
        loop.quit ();
    });
    loop.run (); 
    
    try {

        var scratch = new E.Source.with_uid("On This Computer", null);
        
        if(scratch.has_extension(E.SOURCE_EXTENSION_GOA)) {
            message("GOA found");
        }
        if(scratch.has_extension(E.SOURCE_EXTENSION_ADDRESS_BOOK)) {
            message("Address book found");
        }
        //var local = scratch.get_extension(E.SOURCE_EXTENSION_ADDRESS_BOOK);
        //var client = E.BookClient.connect_sync(scratch, 5, null);
    } catch(GLib.Error e) {
        message("exception encountered, %s", e.message);
    }
}
/*

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
