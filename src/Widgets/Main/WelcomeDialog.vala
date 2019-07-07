/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;
using Envoyer.Globals.Main;
using Envoyer.Globals.Application;

public class Envoyer.Widgets.WelcomeDialog : Gtk.Dialog {
    public signal void authenticated ();

    public WelcomeDialog () {
        Object ();

        build_ui ();
    }

    private void build_ui () {
        get_style_context ().add_class ("welcome-dialog");
        window_position = Gtk.WindowPosition.CENTER;
        modal = true;
        resizable = false;
        border_width = 5;
        set_size_request(1024, 1024);
        set_modal (true);

        var stack = new Gtk.Stack ();
        var webview = new WebKit.WebView ();
        webview.hexpand = true;
        webview.vexpand = true;

        var welcome_label = new Gtk.Label ("Welcome!");
        welcome_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
        welcome_label.halign = Gtk.Align.START;

        var description_label = new Gtk.Label ("Let's get you set up using the app. Enter your information below:");
        description_label.margin_bottom = 40;

        var email_address_label = new Gtk.Label ("E-mail address");
        email_address_label.margin_right = 30;

        var email_address_entry = new Gtk.Entry ();
        email_address_entry.placeholder_text = "you@yourdomain.com";

        var account_name_label = new Gtk.Label ("Account name");
        account_name_label.margin_right = 30;

        var account_name_entry = new Gtk.Entry ();
        account_name_entry.placeholder_text = "Personal";

        var full_name_label = new Gtk.Label ("Full name");

        var full_name_info_image = new Gtk.Image ();
        full_name_info_image.gicon = new ThemedIcon ("dialog-information-symbolic");
        full_name_info_image.pixel_size = 16;
        full_name_info_image.margin_right = 30;
        full_name_info_image.tooltip_text = "Publicly visible. Used in the sender field of your e-mails.";

        var full_name_entry = new Gtk.Entry ();
        full_name_entry.placeholder_text = "John Doe";

        var submit_button = new Gtk.Button.with_label ("Authorize");
        submit_button.halign = Gtk.Align.END;
        submit_button.margin_top = 40;

        var initial_information_grid = new Gtk.Grid ();
        initial_information_grid.halign = Gtk.Align.CENTER;
        initial_information_grid.row_spacing = 5;
        initial_information_grid.attach (email_address_label, 0, 0, 2);
        initial_information_grid.attach (email_address_entry, 2, 0);
        initial_information_grid.attach (account_name_label, 0, 1, 2);
        initial_information_grid.attach (account_name_entry, 2, 1);
        initial_information_grid.attach (full_name_label, 0, 2);
        initial_information_grid.attach (full_name_info_image, 1, 2);
        initial_information_grid.attach (full_name_entry, 2, 2);

        var welcome_screen = new Gtk.Grid ();
        welcome_screen.halign = Gtk.Align.CENTER;
        welcome_screen.valign = Gtk.Align.CENTER;
        welcome_screen.orientation = Gtk.Orientation.VERTICAL;
        welcome_screen.add (welcome_label);
        welcome_screen.add (description_label);
        welcome_screen.add (initial_information_grid);
        welcome_screen.add(submit_button);

        var spinner = new Gtk.Spinner ();
        spinner.set_size_request (40, 40);
        spinner.halign = Gtk.Align.CENTER;
        spinner.valign = Gtk.Align.CENTER;

        var please_wait_label = new Gtk.Label ("Please wait");
        please_wait_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
        please_wait_label.halign = Gtk.Align.START;

        var synchronizing_label = new Gtk.Label ("We are synchronizing with the server. It may take a while.");
        synchronizing_label.margin_bottom = 40;

        var please_wait_grid = new Gtk.Grid ();
        please_wait_grid.orientation = Gtk.Orientation.VERTICAL;
        please_wait_grid.halign = Gtk.Align.CENTER;
        please_wait_grid.valign = Gtk.Align.CENTER;
        please_wait_grid.add(please_wait_label);
        please_wait_grid.add(synchronizing_label);
        please_wait_grid.add(spinner);

        //@TODO move all this to a controller
        submit_button.clicked.connect (() => {
            stack.set_visible_child_name ("webview");

            webview.load_uri ("https://accounts.google.com/o/oauth2/v2/auth?scope=https://mail.google.com/%20email&login_hint=" + email_address_entry.text + "&response_type=code&redirect_uri=com.googleusercontent.apps.577724563203-55upnrbic0a2ft8qr809for8ns74jmqj:&client_id=577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com");
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
                database.add_identity (email_address_entry.text, access_token, refresh_token, expires_at, full_name_entry.text, account_name_entry.text);
                authenticated ();

                stack.set_visible_child_name ("please-wait");
                spinner.start ();

                webview.disconnect (signal_connector);
            }
        });
        //@TODO handle dialog destory... close the application too?
        webview.set_size_request (-1, 600);

        stack.add_named (welcome_screen, "welcome-screen");
        stack.add_named (webview, "webview");
        stack.add_named (please_wait_grid, "please-wait");

        (get_content_area () as Gtk.Box).add (stack);
    }
}
