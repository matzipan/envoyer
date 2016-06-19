public class Mail.Sidebar : Gtk.Grid { //@TODO move to Widget namespace
    private Mail.NestedListBox listbox;

    public signal void session_up ();

    public Sidebar () {
        build_ui ();
        connect_signals ();
        
        //@TODO open the last opened one
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        listbox = new Mail.NestedListBox ();
        listbox.set_size_request (200,250);
        scroll_box.set_size_request (200,250);
        listbox.vexpand = true;

        scroll_box.add (listbox);
        this.add (scroll_box);
    }

    private void clear_list () {
        listbox.unselect_all ();
        var children = listbox.get_children ();

        foreach (Gtk.Widget child in children) {
            if (child is Gtk.ListBoxRow)
                listbox.remove (child);
        }
    }
    
    // @TODO if new accounts get added, update/regenerate the list
    private void build_list () {
        clear_list ();
        
        Mail.Util.SidebarBuilder.build_list (listbox);
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null || !(row is Mail.FolderItem)) {
                return;
            }
            
            folder_threads_list.load_folder (((Mail.FolderItem) row).folder);
            folder_threads_list.grab_focus ();
        });
        
        session_up.connect (build_list);
    }
}
