public class Notes.AccountSummary {
    public E.Source identity_source;
    public Gee.List<Camel.Folder> folder_list;
    
    private bool _expanded = true; //@TODO persist this
    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }
    
    public AccountSummary (E.Source identity_source) {
        this.identity_source = identity_source;
        folder_list = new Gee.LinkedList<Camel.Folder> (null);
    }
}

public class Notes.PagesList : Gtk.Box {    
    public signal void backend_up ();

    private Gtk.ListBox listbox;
    
    private Gee.List<Notes.AccountSummary> summaries_list; 

    private Gtk.Separator separator;
    private Gtk.Label notebook_name;
    private Gtk.Label page_total;

    public PagesList () {
        populate_list ();
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

    public void select_first () {
        listbox.select_row (listbox.get_row_at_index (0));
    }

    public Gtk.ListBoxRow? get_row_from_path (string full_path) {
        foreach (var row in listbox.get_children ()) {
            /*if (row is Notes.PageItem
                && ((Notes.PageItem)row).page.full_path == full_path) {
                return (Gtk.ListBoxRow)row;
            }*/
        }

        return null;
    }

    public void clear_list () {
        listbox.unselect_all ();
        var children = listbox.get_children ();

        foreach (Gtk.Widget child in children) {
            if (child is Gtk.ListBoxRow)
                listbox.remove (child);
        }
    }
    
    private void populate_list () { //@TODO async 
        //@TODO move to account_summary
        summaries_list = new Gee.LinkedList<Notes.AccountSummary> (null);
        
        backend.get_services().foreach((service) => { //@TODO get_stores
            var account_summary = new Notes.AccountSummary (Notes.backend.get_identity_source_for_service (service));
        
            var folders = ((Camel.OfflineStore) service).folders.list();
            folders.foreach((object) => {   
                account_summary.folder_list.add ((Camel.Folder) object);
            });
            
            summaries_list.add(account_summary);
        });        
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
            // @TODO editor.load_file (((Notes.PageItem) row).page);
            editor.give_focus ();
        });
        
        backend_up.connect (() => {
            populate_list ();
            render_list ();
        });
    }
}
