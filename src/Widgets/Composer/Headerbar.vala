/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
