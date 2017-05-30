/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Widgets.Sidebar.AccountFoldersParentItem : Envoyer.FutureGranite.SimpleExpandableItem {
    public AccountFoldersParentItem (Envoyer.Models.Identity identity) {
        base (identity.name);
        
        build_ui ();
    }
    
    public void build_ui () {
        selectable = false;
    }
}
