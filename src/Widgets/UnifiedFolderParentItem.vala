public class Mail.UnifiedFolderParentItem : Mail.SimpleExpandableItem {
    Mail.Models.UnifiedFolderParent parent_folder;

    public UnifiedFolderParentItem (Mail.Models.UnifiedFolderParent parent_folder) {
        base (parent_folder.display_name);
        
        this.parent_folder = parent_folder;
        
        //walk_children (); //@TODO add all the children
        build_ui ();
        connect_signals ();
    }
    
    private void build_ui () {
        //@TODO find a way to add elements like unread counts to the simple expandable item, if not, recreate it
    }
    
    private void connect_signals () {
        //@TODO detect children change on parent_folder
        //@TODO detect name change on parent folder_item which detects it from identity_source
        //@TOOD catch unread_count_changed on parent_folder and change the label
    }

    /*public void add(Gtk.ListBoxRow child) {
        assert(child is Mail.UnifiedFolderChildItem);

        ((Mail.UnifiedFolderChildItem) child).unread_count_changed.connect (recompute_unread_count);

        ((Mail.SimpleExpandableItem) this).add (child);
    }*/


}