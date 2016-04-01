
namespace Mail {
    public Mail.AccountSummariesList account_summaries_list;
    public Mail.Editor editor;
    public Mail.Services.Settings settings;
    public Mail.Services.Backend backend;
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
            
            load_backend ();
        } 
        
        window.show_app ();
    }
    
    
    private async void load_backend() {
        backend = yield new Mail.Services.Backend ();
        
        backend.set_online();
        
        window.backend_up ();        
    }
}
