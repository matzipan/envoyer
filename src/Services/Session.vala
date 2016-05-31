public class Mail.Services.Session : Camel.Session {
    private E.SourceRegistry registry;

    public async Session () {
        Camel.init(E.get_user_data_dir(), false);

        Object(user_data_dir: Path.build_filename (E.get_user_data_dir(), "mail"), user_cache_dir: Path.build_filename (E.get_user_data_dir(), "mail"));
        
        registry = yield new E.SourceRegistry (null); 

        get_mail_account_sources().foreach((source_item) => {
                var extension = source_item.get_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT);           
                // setup autorefresh?  https://git.gnome.org/browse/evolution/tree/libemail-engine/e-mail-session.c#n495


                var service = add_service(source_item.get_uid(), ((E.SourceBackend) extension).get_backend_name(), Camel.ProviderType.STORE);
                
                E.SourceCamel.configure_service(source_item, service); //@TODO
                
                message("%s", online ? "Online" : "Not online");
                
                message("%s", ((E.SourceMailAccount) extension).get_needs_initial_setup() ? "Needs setup" : "Does not need setup");
                
                /*((Camel.OfflineStore) service).set_online_sync(true);

                ((Camel.OfflineStore) service).connect_sync();*/

                GLib.HashTable<weak string,weak string> out_save_setup;
                 
                ((Camel.OfflineStore) service).initial_setup_sync(out out_save_setup); // https://developer.gnome.org/camel/3.19/CamelStore.html#camel-store-initial-setup-sync
                // https://developer.gnome.org/eds/3.20/eds-ESourceCamel.html
                
                ((Camel.Store) service).synchronize_sync(true);
                
            });
    }
    
    public override bool authenticate_sync (Camel.Service service, string? mechanism, GLib.Cancellable? cancellable = null) throws GLib.Error {
        // @todo https://git.gnome.org/browse/evolution/tree/mail/e-mail-ui-session.c#n763
        
        //@TODO get this from camel
        message("Password: ");
        service.set_password(stdin.read_line ());
        
        //@TODO if not accepted, throw gerror?
                
        return service.authenticate_sync(mechanism) == Camel.AuthenticationResult.ACCEPTED;
    }
    
    public GLib.List<E.Source> get_mail_account_sources() {
        var sources = registry.list_sources(E.SOURCE_EXTENSION_MAIL_ACCOUNT);
        
        sources.foreach((source_item) => {
                //@TODO folder.refresh_info_sync();

                if(source_item.get_uid() == "local" || 
                    source_item.get_uid() == "vfolder") {
                        sources.remove_all(source_item);
                    }
            });

        return sources.copy();
    }
    
    public GLib.List<E.Source> get_mail_transport_sources() {
        return null; //@TODO
    }
        
    public GLib.List<Camel.Service> get_services() {
        return list_services();
    }
    
    public E.Source get_identity_source_for_service(Camel.Service service) {
        var account_source = registry.ref_source(service.get_uid());
        var account_extension = (E.SourceMailAccount) account_source.get_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT);
        var identity_uid = account_extension.get_identity_uid();
        
        return registry.ref_source(identity_uid);        
    }

}