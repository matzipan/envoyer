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
        var unified_starred = new Mail.Models.UnifiedFolderParent ("Starred");
        var unified_important = new Mail.Models.UnifiedFolderParent ("Important"); //@TODO this is only a gmail feature, only show if this folder type really exists
        var unified_drafts = new Mail.Models.UnifiedFolderParent ("Drafts");
        var unified_sent = new Mail.Models.UnifiedFolderParent ("Sent");
        var unified_archive = new Mail.Models.UnifiedFolderParent ("Archive");
        var unified_all_mail = new Mail.Models.UnifiedFolderParent ("All Mail");
        var unified_junk = new Mail.Models.UnifiedFolderParent ("Spam");
        var unified_trash = new Mail.Models.UnifiedFolderParent ("Trash");
        
        foreach (var summary in summaries_geelist) {
            unified_inbox.add (new Mail.Models.UnifiedFolderChild (summary.inbox_folder, summary.identity_source));
            
            foreach(var folder in summary.folders_list) {
                if(folder.is_starred) {
                    unified_starred.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_important) {
                    unified_important.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_drafts) {
                    unified_drafts.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_sent) {
                    unified_sent.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_junk) {
                    unified_junk.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_trash) {
                    unified_trash.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_archive) {
                    unified_archive.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
                if(folder.is_all_mail) {
                    unified_all_mail.add (new Mail.Models.UnifiedFolderChild (folder, summary.identity_source));
                }
            }
        }

        listbox.add (new Mail.UnifiedFolderParentItem (unified_inbox));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_starred));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_important));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_drafts));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_sent));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_archive));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_all_mail));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_junk));
        listbox.add (new Mail.UnifiedFolderParentItem (unified_trash));

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
