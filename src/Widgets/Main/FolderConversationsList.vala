/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
    
    public void load_folder (IFolder folder) {
        current_folder = folder;
                        
        render_list ();
        grab_focus ();
        
        // @TODO listbox.select_row (item);
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = false;
        set_size_request (200, -1);

        listbox = new Gtk.ListBox ();
        listbox.set_selection_mode (Gtk.SelectionMode.MULTIPLE);

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        scroll_box.expand = true;
        scroll_box.add (listbox);
        
        add (scroll_box);
        show_all ();
    }
    
    private void clear_list () { //@TODO abstract this? 
        listbox.unselect_all ();
        var children = listbox.get_children ();

        foreach (Gtk.Widget child in children) {
            if (child is Gtk.ListBoxRow)
                listbox.remove (child);
        }
    }
    
    private void render_list () {
        clear_list ();
        
        foreach (var thread in current_folder.threads_list) {
            listbox.add(new FolderConversationItem(thread));
        }
    }

    private void connect_signals () {
        application.load_folder.connect (load_folder);
        
        listbox.row_selected.connect ((row) => {
            if (row == null) return;
            assert(row is FolderConversationItem);

            conversation_viewer.load_conversation_thread (((FolderConversationItem) row).thread);
            
            /*conversation_viewer.give_focus ();*/
        });
    }
}
