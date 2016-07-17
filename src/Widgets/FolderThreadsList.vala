/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Widgets.FolderThreadsList : Gtk.Grid { //@TODO move to Widget namespace
    private Gtk.ListBox listbox; //@TODO abstract this
    private Envoyer.Models.IFolder current_folder;

    //@TODO persist scroller state

    public FolderThreadsList () {
        build_ui ();
        connect_signals ();
    }
    
    public new void grab_focus () {
        //@TODO
    }
    
    public void load_folder (Envoyer.Models.IFolder folder) {
        current_folder = folder;
                        
        render_list();
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = false;
        set_size_request (200, -1);

        listbox = new Gtk.ListBox ();

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
            listbox.add(new Envoyer.Widgets.ConversationItem(thread));
        }
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null) return;
            assert(row is Envoyer.Widgets.ConversationItem);

            conversation_viewer.load_conversation_thread (((Envoyer.Widgets.ConversationItem) row).thread);
            
            //conversation_viewer.give_focus ();
        });
    }
}
