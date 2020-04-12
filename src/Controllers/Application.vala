/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
    public signal void move_to_trash (ConversationThread thread);
    public bool is_initialization { get; construct set; }
    public ConversationThread? current_conversation_thread;

    // @TODO this is a temporary setup to get a simple MVP. This should be streamlined in a different way
    public signal void folder_updated (string folder_name);

    public Application (bool is_initialization) {
        Object (application_id: Constants.PROJECT_FQDN, is_initialization: is_initialization);
    }

    construct {
        session_up.connect (() => { main_window.show_app (); });
        move_to_trash.connect (move_to_trash_handler);
    }

    public override void activate () {
        if (!running) {
            running = true;

            settings = new Envoyer.Models.Settings ();
            gnome_settings = new GLib.Settings ("org.gnome.desktop.interface");

            main_window = new Envoyer.Widgets.Main.Window (this);
            add_window (main_window);

            if (is_initialization) {
                var welcome_dialog = new Envoyer.Widgets.WelcomeDialog ();
                welcome_dialog.set_transient_for (main_window);

                welcome_dialog.authenticated.connect (() => { load_session (); });
                session_up.connect (() => { welcome_dialog.destroy (); });

                welcome_dialog.show_all ();
            } else {
                load_session ();
            }
        } else {
            load_session ();
        }
    }

    private async void load_session () {
        // @TODO find a way to not access database directly
        identities = database.get_identities ();

        //@TODO initialize database here and signal to identity that it is the initial boot so that it fetches the rest of stuff

        foreach (var identity in identities) {
            //@TODO get is_initialization from database_identities
            identity.start_sessions (is_initialization);

            break; //@TODO only hardcoding this to break because for now we only support one identity
        }

        if (is_initialization) {
            identities[0].initialized.connect (() => { session_up (); });
        } else {
            session_up ();
        }
    }

    public void open_composer () {
        var composer_window = new Envoyer.Widgets.Composer.Window ();
        composer_window.show_all ();
    }
    
    public void open_reply_composer () {
        var composer_window = new Envoyer.Widgets.Composer.Window.for_conversation_reply (current_conversation_thread);
        composer_window.show_all ();
    }
    
    public void move_to_trash_handler (ConversationThread thread) {
        //@TODO Add support for multiple identities
        identities[0].move_to_trash (thread);
    }

    public void move_current_conversation_to_trash () {
        if (current_conversation_thread != null) {
            unload_current_conversation_thread ()
            identities[0].move_to_trash (current_conversation_thread);
            //@TODO hide item from conversation list
        }
    }
    
    public void load_conversation_thread (ConversationThread conversation_thread) {
        current_conversation_thread = conversation_thread;
        conversation_viewer.load_conversation_thread (conversation_thread);
    }
    
    public void unload_current_conversation_thread () {
        current_conversation_thread = null;
        conversation_viewer.unload_current_conversation_thread ();
    }
}
