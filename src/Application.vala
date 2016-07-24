/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
namespace Envoyer {
    public Envoyer.Widgets.Sidebar sidebar;
    public Envoyer.Widgets.FolderThreadsList folder_threads_list;
    public Envoyer.Widgets.ConversationViewer conversation_viewer;
    public Envoyer.Services.Settings settings;
    public Envoyer.Services.Session session;
    public Envoyer.Widgets.Window window;
}

public class Envoyer.Application : Granite.Application {
    public const string PROGRAM_NAME = N_(Constants.APP_NAME);
    public const string COMMENT = N_(Constants.PROJECT_DESCRIPTION);
    public const string ABOUT_STOCK = N_("About "+ Constants.APP_NAME);

    public bool running = false;

    public Application () {
        Object (application_id: Constants.PROJECT_FQDN);
    }

    public override void activate () {
        if (!running) {
            running = true;
            
            settings = new Envoyer.Services.Settings ();
            
            window = new Envoyer.Widgets.Window (this);
            this.add_window (window);

            load_session ();
        } 
        
        window.show_app ();
    }
    
    
    private async void load_session() {
        session = yield new Envoyer.Services.Session ();
        
        session.set_online(true);
        
        window.session_up ();
    }
}
