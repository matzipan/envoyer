public class Mail.SimpleExpandableItem : ExpandableItem {
    private Gtk.Grid grid;
    private Gtk.Label title;
    private Gtk.ToggleButton expansion_trigger;
    private string label;
    
    public SimpleExpandableItem (string label) { 
        base ();
               
        this.label = label;
        
        build_ui ();
        connect_signals ();
    }
    
    private void build_ui () {
        //set_activatable (true);  @TODO
        
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
        
        expansion_trigger = new Gtk.ToggleButton ();
        expansion_trigger.get_style_context ().add_class ("expansion-trigger");
        
        grid.add(expansion_trigger);
        grid.add(title);
        
        ((Gtk.Container) this).add(grid);

        load_data ();
        this.show_all ();
    }
    
    private void load_data () {
        this.title.label = "<b>%s</b>".printf(this.label);
    }
    
    private void connect_signals () {
        expansion_trigger.clicked.connect (this.toggle_children);        
    }
}