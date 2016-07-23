/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.FutureGranite.SimpleExpandableItem : Envoyer.FutureGranite.ExpandableItem {
    protected Gtk.Grid grid { get; private set; }
    private Gtk.ToggleButton expansion_trigger;
    private Gtk.Label title;
    private string label;
    
    public SimpleExpandableItem (string label) { 
        base ();
               
        this.label = label;
        
        build_ui ();
        connect_signals ();
    }
    
    public SimpleExpandableItem.with_no_label () {
        base ();

        build_ui_with_no_label ();

        connect_signals ();
    }
    
    private void build_ui_with_no_label () {
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_left = 8;
        grid.margin_right = 8;
        
        expansion_trigger = new Gtk.ToggleButton ();
        expansion_trigger.get_style_context ().add_class ("expansion-trigger");
        expansion_trigger.get_style_context ().remove_class ("button");
        set_expansion_trigger_icon ();
        
        grid.add (expansion_trigger);
        
        ((Gtk.Container) this).add (grid);
        
        show_all ();
    }
    
    private void build_ui () {        
        build_ui_with_no_label ();

        title = new Gtk.Label ("");
        title.get_style_context ().add_class ("h3");
        title.use_markup = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title).xalign = 0;	    

        grid.add (title);

        load_data ();
        show_all ();
    }
    
    private void set_expansion_trigger_icon () {
        expansion_trigger.set_active(expanded);
        
        if(expansion_trigger.get_child () != null) {
            expansion_trigger.remove (expansion_trigger.get_child ()); 
        }
        
        if(expanded) {
            expansion_trigger.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.BUTTON));
        } else {
            expansion_trigger.add (new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.BUTTON));
        }
        
        expansion_trigger.get_child (). show ();
    }
    
    private void load_data () {
        this.title.label = "<b>%s</b>".printf(this.label);
    }
    
    private void connect_signals () {
        expansion_trigger.clicked.connect (this.toggle_children);        
        toggled.connect (this.set_expansion_trigger_icon);
    }
}