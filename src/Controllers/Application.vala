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
    public signal void folder_updated (string folder_name);

    public Application (bool is_initialization) {
        Object (application_id: Constants.PROJECT_FQDN, is_initialization: is_initialization);
    }

    construct {
        session_up.connect (() => { main_window.show_app (); });
    }

    public override void activate () {
        if (!running) {
            running = true;

            settings = new Envoyer.Models.Settings ();
            gnome_settings = new GLib.Settings ("org.gnome.desktop.interface");

            main_window = new Envoyer.Widgets.Main.Window (this);
            add_window (main_window);

            if (is_initialization) {
                var dialog = new Gtk.Dialog ();
                dialog.window_position = Gtk.WindowPosition.CENTER;
                dialog.modal = true;
                dialog.resizable = false;
                dialog.border_width = 5;
                dialog.set_transient_for (main_window);
                dialog.set_size_request(800, 600);
                dialog.set_modal (true);

                var stack = new Gtk.Stack ();
                var webview = new WebKit.WebView ();

                var initial_information_grid = new Gtk.Grid ();
                var username_entry = new Gtk.Entry ();
                username_entry.placeholder_text = "Placeholder text";
                initial_information_grid.add(username_entry);
                var initial_information_submit_button = new Gtk.Button.with_label ("Add");
                initial_information_grid.add(initial_information_submit_button);

                var spinner = new Gtk.Spinner ();

                initial_information_submit_button.clicked.connect (() => {
                    stack.set_visible_child_name ("webview");

                    webview.load_uri ("https://accounts.google.com/o/oauth2/v2/auth?scope=https://mail.google.com/%20email&login_hint=" + username_entry.text + "&response_type=code&redirect_uri=com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj:&client_id=577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com");
                });

                ulong signal_connector = 0;

                signal_connector = webview.load_changed.connect ((event) => {
                    if (event == WebKit.LoadEvent.STARTED && webview.uri.has_prefix("com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj")) {
                        Soup.URI uri = new Soup.URI (webview.uri);
                        var authorization_code = uri.get_query ().replace ("code=", "");

                        var session = new Soup.Session ();

                        var msg = new Soup.Message ("POST", "https://www.googleapis.com/oauth2/v4/token");
                        var encoded_data = Soup.Form.encode ("code",            authorization_code,
                                                             "client_id",       "577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com",
                                                             "client_secret",   "N_GoSZys__JPgKXrh_jIUuOh",
                                                             "redirect_uri",    "com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj:",
                                                             "grant_type",      "authorization_code");

                        msg.set_request ("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, encoded_data.data);
                        session.send_message(msg);

                        var response_object = Json.from_string ((string) msg.response_body.data).get_object ();

                        var access_token = response_object.get_string_member ("access_token");
                        var refresh_token = response_object.get_string_member ("refresh_token");
                        var expires_at = (new DateTime.now_utc ()).add_seconds (response_object.get_int_member ("expires_in"));

                        // @TODO find a way to not access database directly
                        database.add_identity (username_entry.text, access_token, refresh_token, expires_at, "hardcoded full name", "hardcoded account name");
                        load_session ();

                        stack.set_visible_child_name ("spinner");

                        webview.disconnect (signal_connector);
                    }
                });
                //@TODO handle dialog destory... close the application too?
                webview.set_size_request (-1, 600);

                (dialog.get_content_area () as Gtk.Box).add (stack);
                stack.add_named (initial_information_grid, "initial_information_grid");
                stack.add_named (webview, "webview");
                stack.add_named (spinner, "spinner");

                dialog.show_all ();

                session_up.connect (() => { dialog.destroy (); });
            } else {
                load_session ();
            }
        } else {
            load_session ();
        }
    }

    private async void load_session () {
        //@TODO Add support for multiple identities
        // @TODO find a way to not access database directly
        identities = database.get_identities ();

        //@TODO initialize database here and signal to identity that it is the initial boot so that it fetches the rest of stuff

        foreach (var identity in identities) {
            //@TODO get is_initialization from database_identities
            identity.start_sessions (is_initialization);

            break; //@TODO only hardcoding this to break because for now we only support one identity
        }

        if (is_initialization) {
            //@TODO make work with more than one identity
            identities[0].initialized.connect (() => { session_up (); });
        } else {
            session_up ();
        }
    }

    public void open_composer () {
        var composer_window = new Envoyer.Widgets.Composer.Window ();
        composer_window.show_all ();
    }
}
