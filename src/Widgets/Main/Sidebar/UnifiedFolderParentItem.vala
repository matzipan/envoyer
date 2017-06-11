/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
using Envoyer.Models;
using Envoyer.Models.Sidebar;

public class Envoyer.Widgets.Main.Sidebar.UnifiedFolderParentItem : IFolderItem, Basalt.Widgets.SidebarExpandableRow {
    private UnifiedFolderParent parent_folder;
    public IFolder folder { get { return parent_folder; } }
    
    public UnifiedFolderParentItem (UnifiedFolderParent parent_folder) {
            base ((Basalt.Widgets.SidebarExpandableRowModel) parent_folder);
            
            this.parent_folder = parent_folder;
    }
}