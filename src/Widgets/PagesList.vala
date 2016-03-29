public class Notes.PagesList : Gtk.Box {    
    public signal void backend_up ();

    private Gtk.ListBox listbox;
    private Gtk.Frame toolbar;

    private Gtk.Separator separator;
    private Gtk.Button minus_button;
    private Gtk.Button plus_button;
    private Gtk.Label notebook_name;
    private Gtk.Label page_total;


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
        toolbar = build_toolbar ();

        scroll_box.add (listbox);
        this.add (scroll_box);
        this.add (toolbar);
    }

    private Gtk.Frame build_toolbar () {
        var frame = new Gtk.Frame (null);
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        plus_button = new Gtk.Button.from_icon_name ("document-new-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        minus_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        notebook_name = new Gtk.Label ("");
        page_total = new Gtk.Label ("");
        separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);

        minus_button.get_style_context ().add_class ("flat");
        plus_button.get_style_context ().add_class ("flat");

        notebook_name.halign = Gtk.Align.START;
        page_total.halign = Gtk.Align.END;
        minus_button.halign = Gtk.Align.END;
        minus_button.visible = true;
        separator.visible = true;
        notebook_name.hexpand = true;
        minus_button.can_focus = false;
        plus_button.can_focus = false;

        notebook_name.ellipsize = Pango.EllipsizeMode.END;
        notebook_name.get_style_context ().add_class ("h4");
        notebook_name.margin_left = 6;
        notebook_name.margin_right = 6;
        page_total.margin_right = 6;

        box.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        box.add (plus_button);
        box.add (separator);
        box.add (minus_button);

        frame.set_sensitive (false);
        frame.get_style_context ().add_class ("toolbar");
        frame.get_style_context ().add_class ("inline-toolbar");

        frame.add (box);
        frame.show_all ();

        return frame;
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

    public void clear_pages () {
        listbox.unselect_all ();
        var childerns = listbox.get_children ();

        foreach (Gtk.Widget child in childerns) {
            if (child is Gtk.ListBoxRow)
                listbox.remove (child);
        }
    }
    
    private void populate_folders () {
        backend.get_services().foreach((service) => {
            var folders = ((Camel.OfflineStore) service).folders.list();

            folders.foreach((object) => {     
                var folder = (Camel.Folder) object;       
                /*folder.refresh_info_sync();*/
                listbox.add(new Notes.PageItem (folder));
            });

        });
    }


    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            minus_button.sensitive = (row != null);
            if (row == null) return;
            //editor.load_file (((Notes.PageItem) row).page);
            editor.give_focus ();
        });
        
        backend_up.connect (this.populate_folders);
    }
}
