

public class Notes.PagesList : Gtk.Box {    
    public signal void backend_up ();
    
    private Gtk.ListBox listbox;
    private Gee.List<Notes.Models.AccountSummary> summaries_list; 

    public PagesList () {
        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        orientation = Gtk.Orientation.VERTICAL;

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        listbox = new Gtk.ListBox ();
        listbox.set_size_request (200,250);
        scroll_box.set_size_request (200,250);
        listbox.vexpand = true;

        scroll_box.add (listbox);
        this.add (scroll_box);
    }

    public void clear_list () {
        listbox.unselect_all ();
        var children = listbox.get_children ();

        foreach (Gtk.Widget child in children) {
            if (child is Gtk.ListBoxRow)
                listbox.remove (child);
        }
    }
    
    private void populate_list () {
        summaries_list = Notes.Models.AccountSummary.get_summaries_list ();
    }
    
    private void render_list () {
        clear_list ();
        foreach (var summary in summaries_list) { 
            var identity_item = new Notes.IdentityItem (summary.identity_source);
            
            identity_item.toggled.connect (() => {
                summary.expanded = !summary.expanded;
                render_list ();
            });
            
            listbox.add (identity_item);
                        
            if(summary.expanded) {
                //@TODO get special folders
                //@TODO inbox_folder
                //@TODO junk_folder
                //@TODO trash_folder
                //@TODO outbox_folder
                //@TODO all_mail_folder
                //@TODO important_folder
                //@TODO starred_folder
                //@TODO drafts_folder
                //@TODO sent_folder
                //@TODO starred_folder
                //@TODO archive_folder

                foreach(var folder in summary.folder_list) {                    
                    listbox.add(new Notes.FolderItem (folder));
                }
            }
        }
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null) return;
            //if (row is Notes.FolderItem  ((Notes.FolderItem)row).page.full_path == full_path)
            // @TODO editor.load_file (((Notes.PageItem) row).page);
            editor.give_focus ();
        });
        
        backend_up.connect (() => {
            populate_list ();
            render_list ();
        });
    }
}
