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
using Envoyer.Globals.Application;

public class Envoyer.Widgets.Composer.Window : Gtk.Window {
    private Gtk.Entry to_entry;
    private Gtk.Entry subject_entry;
    private Gtk.TextView text_view;
    private Headerbar headerbar;

    public Window () {
        build_ui ();

        connect_signals ();
    }

    private void build_ui () {
        set_default_size (500, 500);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        add (grid);

        grid.attach (new Gtk.Label (_("To:")), 0, 0, 1, 1);

        to_entry = new Gtk.Entry ();
        to_entry.hexpand = true;
        grid.attach (to_entry, 1, 0, 1, 1);

        //@TODO show from dropdown if multiple identities

        grid.attach (new Gtk.Label (_("Subject:")), 0, 1, 1, 1);

        subject_entry = new Gtk.Entry ();
        grid.attach (subject_entry, 1, 1, 1, 1);

        text_view = new Gtk.TextView ();
        text_view.hexpand = true;
        text_view.vexpand = true;
        grid.attach (text_view, 0, 2, 2, 1);

        headerbar = new Headerbar ();
        headerbar.set_title (_("New message"));
        set_titlebar (headerbar);
    }

    private void connect_signals () {
        headerbar.send_clicked.connect (send_clicked_handler);
    }

    private void send_clicked_handler () {
        var message = new Message.for_sending (
            addresses_from_string (to_entry.text),
            addresses_from_string (""), //@TODO
            addresses_from_string (""), //@TODO
            subject_entry.text,
            text_view.buffer.text
        );

        //@TODO Add support for multiple identities
        identities[0].send_message (message);
    }

    private Gee.Collection addresses_from_string (string addresses_string) {
        var address_strings = addresses_string.split (",");
        var addresses = new Gee.ArrayList <Address> ();

        foreach (var address_string in address_strings) {
            addresses.add (new Address ("", address_string));
        }

        return addresses;
    }


}
