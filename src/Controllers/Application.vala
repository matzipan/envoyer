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
    public Gee.List <Identity> identities;
    public Envoyer.Controllers.Application application;
    public Envoyer.Services.Database database;
}

public class Envoyer.Controllers.Application : Granite.Application {
    public bool running = false;
    public signal void session_up ();
    public signal void load_folder (IFolder folder);
    public bool is_initialization { get; construct set; }

    // @TODO this is a temporary setup to get a simple MVP. This should be streamlined in a different way
    public signal void database_updated (string folder_name);

    public Application (bool is_initialization) {
        Object (application_id: Constants.PROJECT_FQDN, is_initialization: is_initialization);
    }

    public override void activate () {
        if (!running) {
            running = true;

            settings = new Envoyer.Models.Settings ();
            gnome_settings = new GLib.Settings ("org.gnome.desktop.interface");

            main_window = new Envoyer.Widgets.Main.Window (this);
            add_window (main_window);

            load_session ();

            if (is_initialization) {
                var dialog = new Gtk.Dialog ();
                dialog.window_position = Gtk.WindowPosition.CENTER;
                dialog.modal = true;
                dialog.resizable = false;
                dialog.border_width = 5;
                dialog.set_transient_for (main_window);
                dialog.set_modal (true);
                var search_label = new Gtk.Label ("Initializing ...");
                var content = dialog.get_content_area () as Gtk.Box;
                content.add (search_label);

                dialog.show_all ();

                session_up.connect (() => { dialog.destroy (); });
            }
        } else if (!is_initialization) {
            main_window.show_app ();
        }
    }

    private async void load_session () {
        //@TODO Add support for multiple identities
        identities = new Gee.ArrayList <Identity> ();

        //@TODO initialize database here and signal to identity that it is the initial boot so that it fetches the rest of stuff

        var identity = yield new Identity (settings.username, settings.password, settings.full_name, settings.account_name, is_initialization);

        //@TODO Add support for multiple identities
        if (is_initialization) {
            identity.initialized.connect (() => { session_up (); });
        } else {
            session_up ();
        }

        identities.add (identity);
    }

    public void open_composer () {
        var composer_window = new Envoyer.Widgets.Composer.Window ();
        composer_window.show_all ();
    }
}
