/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Util.SidebarBuilder : GLib.Object {
    public static void build_list (Envoyer.FutureGranite.NestedListBox listbox) {
        var summaries_geelist = build_summaries_list ();

        foreach (Envoyer.Models.IFolder.Type type in Envoyer.Models.IFolder.Type.all()) {
            var unified_folder = new Envoyer.Models.UnifiedFolderParent(type);
            
            if(type == Envoyer.Models.IFolder.Type.NORMAL) {
                continue;
            }

            foreach (var summary in summaries_geelist) {
                foreach(var folder in summary.folders_list) {
                    if(folder.folder_type == type) {
                        unified_folder.add (new Envoyer.Models.UnifiedFolderChild (folder, summary.identity_source));
                    }
                }
            }
            
            if (!unified_folder.is_empty) {
                listbox.add (new Envoyer.Widgets.UnifiedFolderParentItem (unified_folder));
            }
        }


        foreach (var summary in summaries_geelist) {
            var account_folders_parent = new Envoyer.Widgets.AccountFoldersParentItem (summary.identity_source);

            foreach (var folder in summary.folders_list) {
                if (folder.is_normal) {
                    account_folders_parent.add (new Envoyer.Widgets.FolderItem (folder));
                }
            }
            
            listbox.add (account_folders_parent);
        }
    }
    
    public static Gee.Collection<Envoyer.Models.AccountSummary> build_summaries_list () {  //@TODO async
        var summaries_list = new Gee.ArrayList<Envoyer.Models.AccountSummary> (null);

        Envoyer.session.get_services().foreach((service) => {
            summaries_list.add(new Envoyer.Models.AccountSummary (service));
        });   
        
        return summaries_list;     
    }
}