public class Mail.Sidebar : Gtk.Box { //@TODO move to Widget namespace
    private Mail.NestedListBox listbox;
    private Gee.Collection<Mail.Models.AccountSummary> summaries_geelist; 

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
    
    private void populate_list () {
        summaries_geelist = Mail.Models.AccountSummary.get_summaries_list ();
    }
    
    private void render_list () {
        clear_list ();
        
        //@TODO move to builder
        var unified_inbox = new Mail.Models.UnifiedFolderParent ("Inbox"); //@TODO find a better way for this string
        var unified_inbox_item = new Mail.UnifiedFolderParentItem (unified_inbox);
        listbox.add (unified_inbox_item);
        
        foreach (var summary in summaries_geelist) {
            listbox.add(new Mail.AccountFoldersParentItem (summary));

            var unified_inbox_child = new Mail.Models.UnifiedFolderChild(summary.inbox_folder, summary.identity_source);
            var unified_inbox_child_item = new Mail.UnifiedFolderChildItem (unified_inbox_child);

            unified_inbox.add(unified_inbox_child);
            unified_inbox_item.add(unified_inbox_child_item);
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
        
        session_up.connect (() => {
            populate_list ();
            render_list ();
        });
    }
}
