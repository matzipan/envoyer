/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

using Envoyer.Models;
using Envoyer.Models.Sidebar;
using Envoyer.Globals.Application;

public class Envoyer.Util.SidebarBuilder : GLib.Object {
    public static async Basalt.Widgets.SidebarStore build_list () {
        var store = new Basalt.Widgets.SidebarStore ();

        var summaries_geelist = yield build_summaries_list ();

        foreach (IFolder.Type type in IFolder.Type.unified_folders()) {
            var folders_found = false;

            foreach (var summary in summaries_geelist) {
                foreach (var folder in summary.folders_list) {
                    if(folder.folder_type == type) {
                        folders_found = true;
                    }
                }
            }

            if (folders_found) {
                var unified_folder = new UnifiedFolderParent(type);
                store.append(unified_folder);

                foreach (var summary in summaries_geelist) {
                    foreach(var folder in summary.folders_list) {
                        if(folder.folder_type == type) {
                            unified_folder.children.append (new UnifiedFolderChild (folder, summary.identity));
                        }
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
            summaries_list.add(new AccountSummary (identity));
        };

        return summaries_list;
    }
}
