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

public class Envoyer.Widgets.Main.Sidebar.UnifiedFolderChildItem : IFolderItem, Basalt.Widgets.SidebarRow {
    private UnifiedFolderChild child_folder;
    public IFolder folder { get { return child_folder; } }

    public UnifiedFolderChildItem (UnifiedFolderChild child_folder) {
            base ((Basalt.Widgets.SidebarRowModel) child_folder);

            this.child_folder = child_folder;
    }
}
