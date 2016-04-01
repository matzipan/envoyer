public class Notes.IdentityItem : Gtk.ListBoxRow {

    private Gtk.Grid grid;
    private Gtk.Label title;
    private Gtk.Button button;
    private E.Source source;
    
    public signal void toggled ();

    public IdentityItem (E.Source source) {
        this.source = source;
        build_ui ();
        connect_signals ();
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
        
        button = new Gtk.Button ();
        
        button.add(grid);
        grid.add(title);
        this.add (button);

        load_data ();
        this.show_all ();
    }
    
    private void connect_signals () {
        button.clicked.connect (() => {
            toggled ();
        });
    }

    private void load_data () {
        this.title.label = "<b>%s</b>".printf(source.get_display_name());
    }
}

