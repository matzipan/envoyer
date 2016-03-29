public class Notes.PageItem : Gtk.ListBoxRow {

    private Gtk.Grid grid;
    private Gtk.Label title;
    private Gtk.Label line2;
    private Camel.Folder folder;

    public PageItem (Camel.Folder folder) {
        this.folder = folder;
        build_ui ();
    }

    private void build_ui () {
        set_activatable (true);

        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        title = new Gtk.Label ("");
        title.use_markup = true;
        title.halign = Gtk.Align.START;
        title.get_style_context ().add_class ("h3");
        title.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title).xalign = 0;
	    title.margin_top = 4;
	    title.margin_left = 8;
	    title.margin_bottom = 4;

        line2 = new Gtk.Label ("");
        line2.halign = Gtk.Align.START;
        line2.margin_left = 8;
	    line2.margin_bottom = 4;
	    line2.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) line2).xalign = 0;
        line2.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.hexpand = true;

        this.add (grid);
        grid.add (title);
        grid.add (line2);
        grid.add (separator);

        load_data ();
        this.show_all ();
    }

    private void load_data () {
        this.line2.label = "Unread: %u Total: %d".printf(folder.summary.unread_count, folder.get_message_count());
        message(this.line2.label);
        this.title.label = "<b>%s</b>".printf(folder.get_display_name());
        message(this.title.label);

    }
}

