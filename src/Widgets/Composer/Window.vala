/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
