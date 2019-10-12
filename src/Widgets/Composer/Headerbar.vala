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

public class Envoyer.Widgets.Composer.Headerbar : Gtk.HeaderBar {
    public signal void send_clicked ();

    private Gtk.Button send_button;

    public Headerbar () {
        build_ui ();

        connect_signals ();
    }

    private void build_ui () {
        set_show_close_button (true);

        send_button = new Gtk.Button.from_icon_name ("mail-send", Gtk.IconSize.BUTTON);
        send_button.tooltip_text = (_("Send message")); //@TODO + Key.SEND.to_string ());
        pack_end (send_button);
    }


    private void connect_signals () {
        send_button.clicked.connect (() => { send_clicked (); });
    }
}
