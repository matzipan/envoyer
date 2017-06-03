/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
using Envoyer.Models;
using Envoyer.Models.Sidebar;
 
public class Envoyer.Widgets.Sidebar.Wrapper : Basalt.Widgets.Sidebar {
    public signal void session_up ();

    public Wrapper () {
        connect_signals ();
        
        //@TODO open the last opened one
    }

    // @TODO if new accounts get added, update/regenerate the list
    private void build_list () {
        sidebar.bind_model (Envoyer.Util.SidebarBuilder.build_list ());
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null) {
                return;
            }
            
            if(row is FolderItem) {
                folder_conversations_list.load_folder (((FolderItem) row).folder);
                folder_conversations_list.grab_focus ();
            }
            
            if(row is UnifiedFolderParentItem) {
                folder_conversations_list.load_folder (((UnifiedFolderParentItem) row).folder);
                folder_conversations_list.grab_focus ();
            }
        });
        
        session_up.connect (build_list);
    }
    
    public void bind_model (ListModel? model) {
        listbox.bind_model (model, walk_model_items);
        
        listbox.show_all ();
    }
    
    private Gtk.Widget walk_model_items (Object item) {
        assert (item is Basalt.Widgets.SidebarRowModel);    

        if (item is UnifiedFolderParent) {            
            return new UnifiedFolderParentItem ((UnifiedFolderParent) item);
        } else if (item is UnifiedFolderChild) {
            return new UnifiedFolderChildItem ((UnifiedFolderChild) item);
        } else if (item is AccountFoldersParent) {
            return new AccountFoldersParentItem ((AccountFoldersParent) item);
        } else {
            return new FolderItem ((Folder) item);
        }
    }
}
