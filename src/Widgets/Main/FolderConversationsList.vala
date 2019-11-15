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
using Envoyer.Globals.Main;
using Envoyer.Globals.Application;

public class Envoyer.Widgets.Main.FolderConversationsList : Gtk.Grid {
    private Gtk.ListBox listbox; //@TODO abstract this
    private IFolder current_folder;

    //@TODO persist scroller state

    public FolderConversationsList () {
        build_ui ();
        connect_signals ();
    }

    public new void grab_focus () {
        listbox.grab_focus ();
    }

    public void load_folder_handler (IFolder folder) {
        current_folder = folder;

        listbox.bind_model (folder.conversations_list_model, walk_model_items);

        grab_focus ();
        // @TODO listbox.select_row (item);
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = false;
        set_size_request (200, -1);

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = false;
        listbox.set_selection_mode (Gtk.SelectionMode.MULTIPLE);

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        scroll_box.expand = true;
        scroll_box.add (listbox);

        add (scroll_box);
        show_all ();
    }

    private Gtk.Widget walk_model_items (Object item) {
        var model = (ConversationThread) item;

        return new FolderConversationItem (model);
    }

    private void connect_signals () {
        application.load_folder.connect (load_folder_handler);

        listbox.row_selected.connect ((row) => {
            if (row == null) {
                conversation_viewer.unload_conversation_thread ();
            } else {
                assert(row is FolderConversationItem);

                conversation_viewer.load_conversation_thread (((FolderConversationItem) row).thread);
            }
        });
    }
}
