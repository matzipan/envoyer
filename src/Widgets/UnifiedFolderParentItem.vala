public class Mail.UnifiedFolderParentItem : Mail.SimpleExpandableItem {
    private Mail.Models.UnifiedFolderParent parent_folder;
    private Mail.FolderLabel folder_label;

    public UnifiedFolderParentItem (Mail.Models.UnifiedFolderParent parent_folder) {
        base.with_no_label ();

        this.parent_folder = parent_folder;

        build_ui ();
        connect_signals ();
    }
    
    private void build_ui () {
        folder_label = new Mail.FolderLabel(parent_folder);

        grid.add (folder_label);
        
        foreach (var child in parent_folder.children) { //@TODO replace with a add_all
            add(child);
        }
    }
    
    private void connect_signals () {
        parent_folder.child_added.connect (add); //@TODO reload count and stuffs
        //@TODO parent_folder.child_removed.connect (add);
    }
    
    private void add(Mail.Models.UnifiedFolderChild child) {
        ((Mail.SimpleExpandableItem) this).add(new Mail.UnifiedFolderChildItem (child));
    }

}