public class Session : Camel.Session {
    public Session(string user_data_dir, string user_cache_dir) {
        Object(user_data_dir: user_data_dir, user_cache_dir: user_cache_dir);
    }
    
    public override bool authenticate_sync (Camel.Service service, string? mechanism, GLib.Cancellable? cancellable = null) throws GLib.Error {
        // @todo https://git.gnome.org/browse/evolution/tree/mail/e-mail-ui-session.c#n763
        
        message("Password: ");
        service.set_password(stdin.read_line ());
        
        //@TODO if not accepted, throw gerror?
                
        return service.authenticate_sync(mechanism) == Camel.AuthenticationResult.ACCEPTED;
    }

}