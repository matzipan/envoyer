/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Services.Session : Camel.Session {
    private E.SourceRegistry registry;
    private E.CredentialsPrompter credentials_prompter;
    
    public struct CredentialsPrompterData {
        public Camel.Service service;
        public string mechanism;
    }

    public async Session () {
        Camel.init(E.get_user_data_dir(), false);

        Object(user_data_dir: Path.build_filename (E.get_user_data_dir(), "mail"), user_cache_dir: Path.build_filename (E.get_user_data_dir(), "mail"));
        
        registry = yield new E.SourceRegistry (null); 
        
        credentials_prompter = new E.CredentialsPrompter (registry);

        get_mail_account_sources().foreach((source_item) => {
                var extension = source_item.get_extension(E.SOURCE_EXTENSION_MAIL_ACCOUNT);           

                var service = add_service(source_item.get_uid(), ((E.SourceBackend) extension).get_backend_name(), Camel.ProviderType.STORE);

                E.SourceCamel.configure_service(source_item, service); //@TODO
                
                //debug ("%s", online ? "Online" : "Not online");

                //((Camel.OfflineStore) service).set_online_sync(true); //@TODO only work when internet availalble
                //((Camel.OfflineStore) service).connect_sync();
                //((Camel.OfflineStore) service).prepare_for_offline_sync();

                // https://developer.gnome.org/eds/3.20/eds-ESourceCamel.html @TODO

                ((Camel.Store) service).synchronize_sync(true);

            });
    }

    public override bool authenticate_sync (Camel.Service service, string? mechanism, GLib.Cancellable? cancellable = null) throws GLib.Error {
        /* This function is heavily inspired by mail_ui_session_authenticate_sync in Evolution
         * https://git.gnome.org/browse/evolution/tree/mail/e-mail-ui-session.c */

        /* Do not chain up.  Camel's default method is only an example for
         * subclasses to follow.  Instead we mimic most of its logic here. */

        Camel.ServiceAuthType* authtype;
        bool try_empty_password = false;
        var result = Camel.AuthenticationResult.REJECTED;

        if (mechanism == "none") {
            mechanism = null;
        }

        if(mechanism != null) {
            /* APOP is one case where a non-SASL mechanism name is passed, so
        	 * don't bail if the CamelServiceAuthType struct comes back NULL. */
            authtype = Camel.Sasl.authtype (mechanism);

            /* If the SASL mechanism does not involve a user
             * password, then it gets one shot to authenticate. */
            if (authtype != null && !authtype->need_password) {
                result = service.authenticate_sync (mechanism); //@TODO make async?

                if (result == Camel.AuthenticationResult.REJECTED) {
                    /* @TODO g_set_error (
                        error, CAMEL_SERVICE_ERROR,
                        CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
                        _("%s authentication failed"), mechanism);*/
                }

                return (result == Camel.AuthenticationResult.ACCEPTED);
            }

        	/* Some SASL mechanisms can attempt to authenticate without a
        	 * user password being provided (e.g. single-sign-on credentials),
        	 * but can fall back to a user password.  Handle that case next. */
    		var sasl = new Camel.Sasl (((Camel.Provider*)service.provider)->protocol, mechanism, service);
    		if (sasl != null) {
    			try_empty_password = sasl.try_empty_password_sync ();
    		}
        }

        /*GError *local_error = NULL; @TODO*/

        /* Abort authentication if we got cancelled.
         * Otherwise clear any errors and press on. */
        /*if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
            return FALSE;

            g_clear_error (&local_error); @TODO*/

    	/* Find a matching ESource for this CamelService. */
    	var source = registry.ref_source(service.get_uid());

    	/*if (source == NULL) {
    		g_set_error (@TODO
    			error, CAMEL_SERVICE_ERROR,
    			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
    			_("No data source found for UID '%s'"), uid);
    		return FALSE;
    	}*/

    	result = Camel.AuthenticationResult.REJECTED;

    	if (try_empty_password) {
    		result = service.authenticate_sync (mechanism); //@TODO catch error
    	}

    	if (result == Camel.AuthenticationResult.REJECTED) {
    		/* We need a password, preferrably one cached in
    		 * the keyring or else by interactive user prompt. */

             var data = new CredentialsPrompterData () {
                 service = service,
                 mechanism = mechanism
             };

             return credentials_prompter.loop_prompt_sync (source, E.CredentialsPrompterPromptFlags.ALLOW_SOURCE_SAVE, try_credentials_sync, &data);
    	} else {
            return (result == Camel.AuthenticationResult.ACCEPTED);
        }
    }

    public static bool try_credentials_sync (E.CredentialsPrompter prompter, E.Source source, E.NamedParameters credentials, bool* out_authenticated, CredentialsPrompterData* user_data, GLib.Cancellable? cancellable = null) throws GLib.Error {
        string credential_name = null;

        if (source.has_extension (E.SOURCE_EXTENSION_AUTHENTICATION)) {
            var auth_extension = (E.SourceAuthentication*) source.get_extension(E.SOURCE_EXTENSION_AUTHENTICATION);

            credential_name = auth_extension->dup_credential_name ();

            if (credential_name != null && credential_name.length == 0) {
                credential_name = null;
            }
        }

        if(credential_name == null) {
            credential_name = E.SOURCE_CREDENTIAL_PASSWORD;
        }

        user_data.service.set_password (credentials.get (credential_name));

        Camel.AuthenticationResult result = user_data.service.authenticate_sync (user_data.mechanism); //@TODO catch error
        
        *out_authenticated = (result == Camel.AuthenticationResult.ACCEPTED);

        if (result == Camel.AuthenticationResult.ACCEPTED) {
            var credentials_source = prompter.get_provider ().ref_credentials_source (source);

            if (credentials_source != null) {
                credentials_source.invoke_authenticate_sync (credentials);
            }
        }

        return result == Camel.AuthenticationResult.REJECTED;
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