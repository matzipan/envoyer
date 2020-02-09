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
    private Gtk.Grid grid;
    private Headerbar headerbar;
    private bool is_reply = false;
    private ConversationThread thread_to_reply_to;
    
    public Window.for_conversation_reply (ConversationThread thread) {
        this ();
        
        is_reply = true;
        thread_to_reply_to = thread;
        
        build_ui_for_conversation_reply ();
    }
    
    public Window.for_new_message () {
        this ();
        
        build_ui_for_new_message ();
    }

    public Window () {
        build_ui ();

        connect_signals ();
    }

    private void build_ui () {
        set_default_size (1000, 600);

        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        add (grid);

        grid.attach (new Gtk.Label (_("To:")), 0, 0, 1, 1);

        to_entry = new Gtk.Entry ();
        to_entry.hexpand = true;
        grid.attach (to_entry, 1, 0, 1, 1);

        //@TODO show from dropdown if multiple identities

        text_view = new Gtk.TextView ();
        text_view.hexpand = true;
        text_view.vexpand = true;
        text_view.wrap_mode = Gtk.WrapMode.WORD_CHAR;
        
        set_focus(text_view);
        grid.attach (text_view, 0, 2, 2, 1);

        headerbar = new Headerbar ();
        set_titlebar (headerbar);
    }
    
    private void build_ui_for_new_message () {
        headerbar.set_title (_("New message"));

        grid.attach (new Gtk.Label (_("Subject:")), 0, 1, 1, 1);

        subject_entry = new Gtk.Entry ();
        grid.attach (subject_entry, 1, 1, 1, 1);
    }
    
    private void build_ui_for_conversation_reply () {
        headerbar.set_title (_("Reply"));

        to_entry.text = build_string_from_addresses (thread_to_reply_to.display_addresses); // @TODO this should also take into account "reply-to" fields
        text_view.buffer.set_text (build_quoted_string (thread_to_reply_to.last_received_message.plain_text_content));
        
        Gtk.TextIter start_iter;
        text_view.buffer.get_start_iter (out start_iter);
        text_view.buffer.place_cursor (start_iter);
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
