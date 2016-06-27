/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.UnifiedFolderParentItem : Envoyer.IFolderItem, Envoyer.SimpleExpandableItem {
    private Envoyer.Models.UnifiedFolderParent parent_folder;
    public Envoyer.Models.IFolder folder { get { return parent_folder; } }

    private Envoyer.FolderLabel folder_label;
    
    public UnifiedFolderParentItem (Envoyer.Models.UnifiedFolderParent parent_folder) {
        base.with_no_label ();

        this.parent_folder = parent_folder;

        build_ui ();
        connect_signals ();
    }
    
    private void build_ui () {
        folder_label = new Envoyer.FolderLabel(parent_folder);

        grid.add (folder_label);
        
        foreach (var child in parent_folder.children) { //@TODO replace with a add_all
            add(child);
        }
    }
    
    private void connect_signals () {
        parent_folder.child_added.connect (add); //@TODO reload count and stuffs
        //@TODO parent_folder.child_removed.connect (add);
    }
    
    private new void add(Envoyer.Models.UnifiedFolderChild child) {
        ((Envoyer.SimpleExpandableItem) this).add(new Envoyer.UnifiedFolderChildItem (child));
    }

}