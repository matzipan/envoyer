/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
using Envoyer.Models;
using Envoyer.Models.Sidebar;

public class Envoyer.Widgets.Main.Sidebar.UnifiedFolderChildItem : IFolderItem, Basalt.Widgets.SidebarRow {
    private UnifiedFolderChild child_folder;
    public IFolder folder { get { return child_folder; } }
    
    public UnifiedFolderChildItem (UnifiedFolderChild child_folder) {
            base ((Basalt.Widgets.SidebarRowModel) child_folder);
            
            this.child_folder = child_folder;
    }
}