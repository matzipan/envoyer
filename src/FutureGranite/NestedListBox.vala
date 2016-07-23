/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.FutureGranite.NestedListBox : Gtk.ListBox {
    private Gee.ArrayList<Envoyer.FutureGranite.ExpandableItem> root_items_list;
    
    public NestedListBox () {
        root_items_list = new Gee.ArrayList<Envoyer.FutureGranite.ExpandableItem>();
    }
    
    public new void add (Gtk.ListBoxRow row) {
        ((Gtk.ListBox) this).add(row);

        if(row is Envoyer.FutureGranite.ExpandableItem) {
            var expandable_item_row = (Envoyer.FutureGranite.ExpandableItem) row;
            
            root_items_list.add(expandable_item_row);
            
            foreach(var child in expandable_item_row.children) {                
                ((Gtk.ListBox) this).add(child);
                
                if(!expandable_item_row.expanded) {
                    child.hide ();
                }
            }
            
            expandable_item_row.child_added.connect(refresh);
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