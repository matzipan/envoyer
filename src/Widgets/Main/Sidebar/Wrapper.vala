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
using Envoyer.Globals.Main;
using Envoyer.Globals.Application;

public class Envoyer.Widgets.Main.Sidebar.Wrapper : Basalt.Widgets.Sidebar {
    public Wrapper () {
        connect_signals ();

        //@TODO open the last opened one
    }

    // @TODO if new accounts get added, update/regenerate the list
    private async void build_list () {
        sidebar.bind_model (yield Envoyer.Util.SidebarBuilder.build_list ());
    }

    private void connect_signals () {
        listbox.row_selected.connect ((row) => {
            if (row == null) {
                return;
            }

            if(row is FolderItem) {
                application.load_folder (((FolderItem) row).folder);
            }

            if(row is UnifiedFolderParentItem) {
                application.load_folder (((UnifiedFolderParentItem) row).folder);
            }
        });

        application.session_up.connect (build_list);
    }

    public void bind_model (ListModel? model) {
        listbox.bind_model (model, walk_model_items);

        listbox.show_all ();
    }

    private Gtk.Widget walk_model_items (Object item) {
        assert (item is Basalt.Widgets.SidebarRowModel);

        if (item is UnifiedFolderParent) {
            return new UnifiedFolderParentItem ((UnifiedFolderParent) item);
        } else if (item is UnifiedFolderChild) {
            return new UnifiedFolderChildItem ((UnifiedFolderChild) item);
        } else if (item is AccountFoldersParent) {
            return new AccountFoldersParentItem ((AccountFoldersParent) item);
        } else {
            return new FolderItem ((Folder) item);
        }
    }
}
