async void foo () throws GLib.Error {
    
    var registry = yield new E.SourceRegistry (null); 
    
    //registry.debug_dump(null);
    
    var sourceList = registry.list_sources(null);
    
    Camel.init(E.get_user_data_dir(), false);
        
    var session = new Session(Path.build_filename (E.get_user_data_dir(), "mail"), Path.build_filename (E.get_user_data_dir(), "mail"));
    
    session.set_online(true);    
        
    foreach(var source in sourceList) {        
        if(source.has_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT)) {
            message(source.get_display_name());

            message("MAIL_ACCOUNT found");
            
            var extension = source.get_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT);            
                        
            if(source.has_extension(E.SourceCamel.get_extension_name(((E.SourceBackend) extension).get_backend_name()))) {
                message("Backend %s %s found", ((E.SourceBackend) extension).get_backend_name(), source.get_uid());
                                
                if(source.get_uid() != "local" && source.get_uid() != "vfolder") {
                    var service = session.add_service(source.get_uid(), ((E.SourceBackend) extension).get_backend_name(), Camel.ProviderType.STORE);
                    // setup autorefresh?  https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n495
                    
                    E.SourceCamel.configure_service(source, service);
                    
                    message("%s", session.online ? "Online" : "Not online");
                    
                    message("%s", ((E.SourceMailAccount) extension).get_needs_initial_setup() ? "Needs setup" : "Does not need setup");
                                        
                    try {
                        
                        ((Camel.OfflineStore) service).set_online_sync(true);

                        ((Camel.OfflineStore) service).connect_sync();

                        GLib.HashTable<weak string,weak string> out_save_setup;
                         
                        ((Camel.OfflineStore) service).initial_setup_sync(out out_save_setup); // https://developer.gnome.org/camel/3.19/CamelStore.html#camel-store-initial-setup-sync
                        
                        ((Camel.Store) service).synchronize_sync(true);
                        
                        /*var root = ((Camel.OfflineStore) service).get_folder_info_sync(null, Camel.StoreGetFolderInfoFlags.SUBSCRIBED |Camel.StoreGetFolderInfoFlags.RECURSIVE | Camel.StoreGetFolderInfoFlags.NO_VIRTUAL);
                        
                        message("%s (unread: %d, total: %d)", root.display_name, root.unread, root.total);
                        
                        var bla_folder = ((Camel.OfflineStore) service).get_folder_sync("INBOX", 0);
                        //var bla_folder = ((Camel.OfflineStore) service).get_folder_sync(folder_info.display_name, 0);
                        
                        message("Display name: %s", bla_folder.get_display_name());
                                                
                        var inbox_folder = ((Camel.OfflineStore) service).get_inbox_folder_sync();*/
                        
                        var folders = ((Camel.OfflineStore) service).folders.list();
                        
                        folders.foreach((folder) => {
                            var cf = (Camel.Folder) folder;
                            
                            cf.refresh_info_sync();
                            
                            message("Folder name: %s, (unread: %u, total: %d)", cf.get_display_name(), cf.summary.unread_count, cf.get_message_count());
                            
                            /*cf.get_summary().foreach((message_info) => {
                                message("%x", (uint) message_info);
                                    //message("- %s", (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT));
                                    //message_info.dump();
                                });*/
                                
                            cf.get_uids().foreach((uid) => {
                                    var message_info = cf.get_message_info(uid);
                                    message("BLALALALALALALAL - %s", (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT));
                                    message_info.dump();
                                });
                        });
                        
                        
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
            message(source.get_display_name());

            message("MAIL_TRANSPORT found");
        }
        
        var providerList = Camel.Provider.list(true);
        
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