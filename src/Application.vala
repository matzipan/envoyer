
namespace Notes {
    public Notes.PagesList pages_list;
    public Notes.Editor editor;
    public Notes.Services.Settings settings;
    public Notes.Services.Backend backend;
    public Notes.Window window;        
}

public class Notes.Application : Granite.Application {
    public const string PROGRAM_NAME = N_(Constants.APP_NAME);
    public const string COMMENT = N_(Constants.PROJECT_DESCRIPTION);
    public const string ABOUT_STOCK = N_("About "+ Constants.APP_NAME);

    public bool running = false;

    public Application () {
        Object (application_id: "org.pantheon.mail-ng");
    }

    public override void activate () {
        if (!running) {
            settings = new Notes.Services.Settings ();
            
            window = new Notes.Window (this);
            this.add_window (window);

            running = true;
            
            load_backend ();
        } 
        
        window.show_app ();
    }
    
    
    private async void load_backend() {
        backend = yield new Notes.Services.Backend ();
        
        backend.set_online();
        
        window.backend_up ();        
    }
}
