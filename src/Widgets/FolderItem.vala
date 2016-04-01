public class Notes.FolderItem : Gtk.ListBoxRow {
    public Camel.Folder folder { get { return _folder; } }

    private Gtk.Grid grid;
    private Gtk.Label title;
    private Gtk.Label unread_count;
    private Camel.Folder _folder;

    public FolderItem (Camel.Folder folder) {
        _folder = folder;
        build_ui ();
    }

    private void build_ui () {
        set_activatable (true);

        grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("h3");
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_left = 8;
        grid.margin_right = 8;

        title = new Gtk.Label ("");
        title.use_markup = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title).xalign = 0;	    

        unread_count = new Gtk.Label ("");
        unread_count.halign = Gtk.Align.START;
	    unread_count.ellipsize = Pango.EllipsizeMode.END;
        unread_count.margin_left = 8;
        ((Gtk.Misc) unread_count).xalign = 0;
        unread_count.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        this.add (grid);
        grid.add (title);
        grid.add (unread_count);

        load_data ();
        this.show_all ();
    }

    private void load_data () {
        this.unread_count.label = "%u".printf(folder.summary.unread_count);
        this.title.label = "<b>%s</b>".printf(folder.get_display_name());

    }
}

