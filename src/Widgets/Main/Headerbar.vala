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

using Envoyer.Globals.Application;

public class Envoyer.Widgets.Main.Headerbar : Gtk.HeaderBar {
    private Gtk.Button compose_button;
    private Gtk.Button reply_button;
    private Gtk.MenuButton menu_button;

    public Headerbar () {
        build_ui ();

        connect_signals ();
    }

    private void build_ui () {
        set_show_close_button (true);
        Granite.Widgets.Utils.set_theming_for_screen (get_screen (), CUSTOM_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // @TODO use this instead of set_theming when granite gets fixed
        //var headerbar_color = Gdk.RGBA();
        //headerbar_color.parse("#F7AC37");
        //Granite.Widgets.Utils.set_color_primary (this, headerbar_color);

        compose_button = new Gtk.Button.from_icon_name ("mail-message-new", Gtk.IconSize.LARGE_TOOLBAR);
        compose_button.tooltip_text = (_("Compose message")); //@TODO + Key.COMPOSE.to_string ());
        pack_start (compose_button);

        menu_button = new Gtk.MenuButton ();
        menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
        pack_end (menu_button);
        
        //@TODO hide when no conversation loaded
        reply_button = new Gtk.Button.from_icon_name ("mail-reply-sender", Gtk.IconSize.LARGE_TOOLBAR);
        reply_button.tooltip_text = (_("Reply to conversation")); //@TODO + Key.REPLY.to_string ());
        pack_end (reply_button);

        var menu = new Gtk.Menu ();
        menu.add (new Gtk.MenuItem.with_label (_("Accounts")));
        menu.add (new Gtk.MenuItem.with_label (_("Quit")));
        menu.show_all ();
        menu_button.set_popup (menu);
    }

    private void compose_button_clicked () {
        application.open_composer ();
    }
    
    private void reply_button_clicked () {
        application.open_reply_composer ();
    }

    private void connect_signals () {
        compose_button.clicked.connect (compose_button_clicked);
        reply_button.clicked.connect (reply_button_clicked);
    }

    private const string CUSTOM_STYLESHEET = """
        @define-color colorPrimary #F7AC37;
        @define-color textColorPrimary rgba(30,30,30,0.7);

    """;
}
