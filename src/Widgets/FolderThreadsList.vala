

public class Mail.FolderThreadsList : Gtk.Box { //@TODO move to Widget namespace    
    private Gtk.ListBox listbox; //@TODO abstract this
    private Gee.List<Mail.Models.ConversationThread> threads_geelist; //@TODO make this more dynamic? it currently loads all the thrads into memory
    private Camel.Folder current_folder;

    //@TODO persist scroller state

    public FolderThreadsList () {
        build_ui ();
        connect_signals ();
    }
    
    public void grab_focus () {
        //@TODO
    }
    
    public void load_folder (Camel.Folder folder) {
        current_folder = folder;
                
        threads_geelist = Mail.Models.ConversationThread.get_threads_list (current_folder);
        
        render_list();
    }

    private void build_ui () { //@TODO abstract this ?
        orientation = Gtk.Orientation.VERTICAL;

        var scroll_box = new Gtk.ScrolledWindow (null, null);
        listbox = new Gtk.ListBox ();
        listbox.set_size_request (200,250);
        scroll_box.set_size_request (200,250);
        listbox.vexpand = true;

        scroll_box.add (listbox);
        this.add (scroll_box);
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

        foreach (var thread in threads_geelist) { 
            listbox.add(new Mail.ConversationItem(thread));
        }
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null) return;
            //if (row is Mail.FolderItem  ((Mail.FolderItem)row).page.full_path == full_path)
            // @TODO editor.load_file (((Mail.PageItem) row).page);
            //editor.give_focus ();
        });
    }
}
