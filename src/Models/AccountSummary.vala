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

public class Envoyer.Models.AccountSummary : GLib.Object {
    private bool _expanded = true; //@TODO persist this

    //@TODO maybe the summary should have properties for each of the special folders: inbox, sent, drafts, etc.

    public Identity identity { get; construct set; }

    public signal void folder_list_changed ();

    public Gee.Collection<Folder> folders_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var folders_list_copy = new Gee.ArrayList<Envoyer.Models.Folder> ();
            folders_list_copy.add_all (_folder_list);
            return folders_list_copy;
        }
    }

    private Gee.ArrayList<Folder> _folder_list = new Gee.ArrayList<Folder> (null);

    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }

    public AccountSummary (Identity identity) {
        Object (identity: identity);
    }

    construct {
        _folder_list.add_all (identity.get_folders ());
    }
}
