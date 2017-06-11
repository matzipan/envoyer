/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
using Envoyer.Models;
 
public class Envoyer.Widgets.Main.Sidebar.FolderItem : IFolderItem, Basalt.Widgets.SidebarRow {
    private Folder _folder;
    public IFolder folder { get { return _folder; } }
    
    public FolderItem (Folder model) {
            base (model);
            
            this._folder = model;
    }
}