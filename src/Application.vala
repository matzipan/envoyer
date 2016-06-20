
namespace Mail {
    public Mail.Sidebar sidebar;
    public Mail.FolderThreadsList folder_threads_list;
    public Mail.Services.Settings settings;
    public Mail.Services.Session session;
    public Mail.Window window;        
}

public class Mail.Application : Granite.Application {
    public const string PROGRAM_NAME = N_(Constants.APP_NAME);
    public const string COMMENT = N_(Constants.PROJECT_DESCRIPTION);
    public const string ABOUT_STOCK = N_("About "+ Constants.APP_NAME);

    public bool running = false;

    public Application () {
        Object (application_id: "org.pantheon.mail-ng");
    }

    public override void activate () {
        if (!running) {
            settings = new Mail.Services.Settings ();
            
            window = new Mail.Window (this);
            this.add_window (window);

            running = true;

            load_session.begin ();
        } 
        
        window.show_app ();
    }
    
    
    private async void load_session() {
        session = yield new Mail.Services.Session (); //@maybe remove the yield
        
        session.set_online(true);
        
        window.session_up ();        
    }
}
