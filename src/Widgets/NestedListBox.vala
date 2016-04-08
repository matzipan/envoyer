public class Mail.NestedListBox : Gtk.ListBox {
    private Gee.ArrayList<Mail.ExpandableItem> root_items_list;
    
    public NestedListBox () {
        root_items_list = new Gee.ArrayList<Mail.ExpandableItem>();
    }
    
    public void add (Gtk.ListBoxRow row) {
        ((Gtk.ListBox) this).add(row);

        if(row is Mail.ExpandableItem) {
            var expandable_item_row = (Mail.ExpandableItem) row;
            
            root_items_list.add(expandable_item_row);
            
            foreach(var child in expandable_item_row.children) {                
                ((Gtk.ListBox) this).add(child);
            }
            
            expandable_item_row.child_added.connect(() => {
                refresh ();
            });
            
        }
    }
    
    private void refresh () {
        //@TODO make it so that it listens for child added and rebuilds the list, but keeps the same state

        clear ();
        foreach(var root_item in root_items_list) {
            add (root_item);
        }
    }
    
    private void clear () {
        foreach(var child in get_children ()) {
            remove (child);
        }
    }
}