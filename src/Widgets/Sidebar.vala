public class Mail.Sidebar : Gtk.Box { //@TODO move to Widget namespace
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

        var summaries_geelist = Mail.Models.AccountSummary.get_summaries_list ();

        // I tried applying several different patterns to building this list.
        // Although I am not fond of it, I always seem to come back to this format
        var unified_inbox = new Mail.Models.UnifiedFolderParent ("Inbox");
        foreach (var summary in summaries_geelist) {
            unified_inbox.add (new Mail.Models.UnifiedFolderChild (summary.inbox_folder, summary.identity_source));
        }

        listbox.add (new Mail.UnifiedFolderParentItem (unified_inbox));

        foreach (var summary in summaries_geelist) {
            listbox.add (new Mail.AccountFoldersParentItem (summary));
        }
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
