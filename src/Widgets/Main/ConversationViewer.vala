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

public class Envoyer.Widgets.Main.ConversationViewer : Gtk.Grid {
    private Gtk.ListBox listbox; //@TODO abstract this
    private Gtk.ScrolledWindow scrollbox; //@TODO abstract this
    private Granite.Widgets.OverlayBar conversation_overlay;
    private ConversationThread conversation_thread;

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
            var viewer = new MessageViewer(item);
            viewer.link_mouse_in.connect (show_overlay_with_text);
            viewer.link_mouse_out.connect (hide_overlay);
            listbox.add(viewer);
        }

        listbox.show_all ();
    }

    public void load_conversation_thread (ConversationThread conversation_thread) {
        this.conversation_thread = conversation_thread;

        load_data ();
    }
    
    public void unload_current_conversation_thread () {
        clear ();
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
