/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;
using Envoyer.Models.Sidebar;
using Envoyer.Globals.Application;

public class Envoyer.Util.SidebarBuilder : GLib.Object {
    public static async Basalt.Widgets.SidebarStore build_list () {
        var store = new Basalt.Widgets.SidebarStore ();

        var summaries_geelist = yield build_summaries_list ();

        foreach (IFolder.Type type in IFolder.Type.unified_folders()) {
            var unified_folder = new UnifiedFolderParent(type);
            store.append(unified_folder);

            foreach (var summary in summaries_geelist) {
                foreach(var folder in summary.folders_list) {
                    if(folder.folder_type == type) {
                        unified_folder.children.append (new UnifiedFolderChild (folder, summary.identity));
                    }
                }
            }

            // @TODO if there is only one unified folder child, don't show the parent as expandable
        }


        foreach (var summary in summaries_geelist) {
            var account_folders_parent = new AccountFoldersParent (summary.identity);

            foreach (var folder in summary.folders_list) {
                if (folder.is_normal) {
                    account_folders_parent.children.append (folder);
                }
            }

            store.append (account_folders_parent);
        }

        return store;
    }

    public static async Gee.Collection<AccountSummary> build_summaries_list () {  //@TODO async
        var summaries_list = new Gee.ArrayList<AccountSummary> (null);

        foreach (var identity in identities) {
            summaries_list.add(yield new AccountSummary (identity));
        };

        return summaries_list;
    }
}
