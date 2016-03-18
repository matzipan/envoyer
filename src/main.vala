async void foo () throws GLib.Error {
    var registry = yield new E.SourceRegistry (null); 
    
    registry.debug_dump(null);
    
    var sourceList = registry.list_sources(null);
    
    var providerList = Camel.Provider.list(true);
    
    var session = new Session(Path.build_filename ("data","eds-sample"), Path.build_filename ("cache","eds-sample"));
    
    session.set_online(true);
    
        
    foreach(var source in sourceList) {
        message(source.get_display_name());
        
        if(source.has_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT)) {
            message("MAIL_ACCOUNT found");
            
            var extension = source.get_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT);
            
            if(source.has_extension(E.SourceCamel.get_extension_name(((E.SourceBackend) extension).get_backend_name()))) {
                message("Backend %s %s found", ((E.SourceBackend) extension).get_backend_name(), source.get_uid());
                                
                if(source.get_uid() != "local" && source.get_uid() != "vfolder") {
                    var service = session.add_service(source.get_uid(), ((E.SourceBackend) extension).get_backend_name(), Camel.ProviderType.STORE);
                    
                    // setup autorefresh?  https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n495
                    
                    message("%s", session.online ? "Online" : "Not online");
                    
                    message("%s", ((E.SourceMailAccount) extension).get_needs_initial_setup() ? "Needs setup" : "Does not need setup");

                    
                    try {
                        service.connect_sync();
                        ((Camel.OfflineStore) service).set_online_sync(true);

                        GLib.HashTable<weak string,weak string> out_save_setup;
                        
                        // (process:1662): camel-CRITICAL **: network_service_connect_sync: assertion 'connectable != NULL' failed
                        //** Message: main.vala:51: Exception encountered: You must be working online to complete this operation
                         
                        ((Camel.Store) service).initial_setup_sync(out out_save_setup); // https://developer.gnome.org/camel/3.19/CamelStore.html#camel-store-initial-setup-sync
                        
                        /*((Camel.Store) service).synchronize_sync(false); https://developer.gnome.org/camel/3.19/CamelStore.html#camel-store-synchronize-sync
                        ((Camel.Store) service).get_folder_info_sync("", Camel.StoreGetFolderInfoFlags.RECURSIVE); https://developer.gnome.org/camel/3.19/CamelStore.html#camel-store-get-folder-info*/

                        var inbox_folder = ((Camel.Store) service).get_inbox_folder_sync();
                        
                        
                    } catch(GLib.Error e) {
                        message("Exception encountered: %s", e.message);
                    }
     
                    //https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n1462
                    //https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n1626
                    //https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n1661
                    //https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n1874
                }
            } else {
                //https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n644 configure local store
            }
        }
        
        if(source.has_extension(E.SOURCE_EXTENSION_MAIL_TRANSPORT)) {
            message("MAIL_TRANSPORT found");
        }
        
        providerList.foreach((provider) => {
            if(source.has_extension(E.SourceCamel.get_extension_name(provider.protocol))) {
                message("CAMEL %s found", provider.protocol);
            }
        });
    }
}
void main() {
    var loop = new MainLoop ();
    foo.begin ((obj, res) => {
        try {
            foo.end (res);    
        } catch(GLib.Error e) {
            message("Exception encountered: %s", e.message);
        }
        loop.quit ();
    });
    loop.run (); 
}