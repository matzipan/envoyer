/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.ConversationViewer : Gtk.Grid {
    private Gtk.ListBox listbox; //@TODO abstract this
    private Gtk.ScrolledWindow scrollbox; //@TODO abstract this
    private Granite.Widgets.OverlayBar conversation_overlay;
    private Envoyer.Models.ConversationThread conversation_thread;

    public ConversationViewer () {
        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        //@TODO add find dialog

        listbox = new Gtk.ListBox ();
        
        scrollbox = new Gtk.ScrolledWindow (null, null);
        scrollbox.expand = true;
        scrollbox.add (listbox);
        scrollbox.hscrollbar_policy = Gtk.PolicyType.NEVER;

        var view_overlay = new Gtk.Overlay();
        view_overlay.add(scrollbox);

        conversation_overlay = new Granite.Widgets.OverlayBar(view_overlay);

        orientation = Gtk.Orientation.VERTICAL;
        hexpand = true;
        add (view_overlay);
    }
    
    private void connect_signals () {
        realize.connect(hide_overlay);
    }

    private void load_data () {
        clear ();

        foreach (var item in conversation_thread.messages_list) {
            var viewer = new Envoyer.Widgets.MessageViewer(item);
            viewer.scroll_event.connect(handle_scroll_event);
            viewer.link_mouse_in.connect (show_overlay_with_text);
            viewer.link_mouse_out.connect (hide_overlay);
            listbox.add(viewer);
        }

        listbox.show_all ();
    }
    
    private bool handle_scroll_event (Gdk.EventScroll event) {
        /*
         * I admit that this solution feels hacky, but I could not find any other working solution
         * for propagating the scroll event upwards. 
         */
        scrollbox.scroll_event (event);
        
        return Gdk.EVENT_PROPAGATE;
    }
    
    public void load_conversation_thread (Envoyer.Models.ConversationThread conversation_thread) {
        this.conversation_thread = conversation_thread;

        load_data ();
    }
    
    public void show_overlay_with_text (string text) {
        conversation_overlay.status = text;
        conversation_overlay.show_all();
    }

    public void hide_overlay () {
        conversation_overlay.hide ();
    }

    private void clear () {
        foreach(var child in listbox.get_children ()) {
            listbox.remove (child);
        }
    }
}
