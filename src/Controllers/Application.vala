/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;
using Envoyer.Globals.Main;
using Envoyer.Globals.Application; 

namespace Envoyer.Globals.Application {
    public Envoyer.Models.Settings settings;
    public GLib.Settings gnome_settings;
    public GLib.List<Envoyer.Models.Identity> identities;
    public Envoyer.Controllers.Application application;
}

public class Envoyer.Controllers.Application : Granite.Application {
    public bool running = false;
    public signal void session_up ();
    public signal void load_folder (IFolder folder);

    public Application () {
        Object (application_id: Constants.PROJECT_FQDN);
    }

    public override void activate () {
        if (!running) {
            running = true;
            
            settings = new Envoyer.Models.Settings ();
            gnome_settings = new GLib.Settings ("org.gnome.desktop.interface");

            main_window = new Envoyer.Widgets.Main.Window (this);
            add_window (main_window);

            load_session ();
        } 
        
        main_window.show_app ();
    }
    
    
    private async void load_session() {
        //@TODO Add support for multiple identities
        var identity = yield new Envoyer.Models.Identity (settings.username, settings.password, settings.account_name);
        
        identities.append (identity);
        
        session_up ();
    }
}
