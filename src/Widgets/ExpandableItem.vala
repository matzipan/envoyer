public abstract class Mail.ExpandableItem : Gtk.ListBoxRow {
    public signal void child_added (); //@TODO maybe pass the child as a parameter
    public signal void child_removed (); //@TODO maybe pass the child as a parameter
    
    public signal void toggled (bool expanded);
    
    public Gee.Collection<Gtk.ListBoxRow> children { 
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var children_list_copy = new Gee.ArrayList<Gtk.ListBoxRow> ();
            children_list_copy.add_all (_children);
            return children_list_copy;
        }
    }
    private Gee.ArrayList<Gtk.ListBoxRow> _children = new Gee.ArrayList<Gtk.ListBoxRow> ();

    public bool expanded { get; private set; } //@TODO sync with account summary
    
    public ExpandableItem () { }
    
    public void toggle_children () {
        if(expanded) {
            collapse_all ();
        } else {
            expand_all ();
        }    
    }
    
    public void collapse_all (bool inclusive = true, bool recursive = true) {
        //@TODO implement recursion
        foreach(Gtk.Widget widget in _children) {
            widget.hide ();
        }

        expanded = false;
        
        toggled (expanded);
    }
    
    public void expand_all (bool inclusive = true, bool recursive = true) {
        //@TODO implement recursion
        foreach(Gtk.Widget widget in _children) {
            widget.show ();
        }
        
        expanded = true;

        toggled (expanded);
    }
    
    public void add(Gtk.ListBoxRow child) {
        _children.add(child);
        child_added ();
    }
    
    //@TODO add_all
    //public void clear () @TODO
    //public void collapse_with_parents () @TODO
    //public bool contains (Item item) @TODO
    //public void expand_with_parents () @TODO
    //public void remove (Item item) @TODO
}