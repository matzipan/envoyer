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

public class Envoyer.Models.Sidebar.UnifiedFolderChild : IFolder, Basalt.Widgets.SidebarRowModel {
    private Identity identity;
    private Folder _folder;

    public bool is_inbox { get { return _folder.is_inbox; } }
    public bool is_trash { get { return _folder.is_trash; } }
    public bool is_sent { get { return _folder.is_sent; } }
    public bool is_normal { get { return _folder.is_normal; } }
    public bool is_spam { get { return _folder.is_spam; } }
    public bool is_starred { get { return _folder.is_starred; } }
    public bool is_all_mail { get { return _folder.is_all_mail; } }
    public bool is_drafts { get { return _folder.is_drafts; } }
    public bool is_archive { get { return _folder.is_archive; } }
    public bool is_important { get { return _folder.is_important; } }
    public bool is_unified { get { return _folder.is_unified; } }

    public IFolder.Type folder_type { get { return _folder.folder_type; } }

    public uint unread_count { get { return _folder.unread_count; } }
    public uint total_count { get { return _folder.total_count; } }
    public uint recent_count { get { return _folder.recent_count; } }

    public Gee.List <ConversationThread> threads_list { owned get { return _folder.threads_list; } }

    public FolderConversationsListModel conversations_list_model { owned get { return _folder.conversations_list_model; } }

    public string name { get { return identity.account_name; } }

    public UnifiedFolderChild (Folder folder, Identity identity) {
        base (identity.account_name);

        this.identity = identity;
        _folder = folder;

        //@TODO listen to total_count_changed signal and change the icon accordingly
        icon_name = IFolder.get_icon_for_folder (this);

        connect_signals ();
    }

    public void connect_signals () {
        // @TODO watch for identity display_name change

        _folder.unread_count_changed.connect ((new_unread_count) => {
            unread_count_changed (new_unread_count);
        });

        _folder.total_count_changed.connect ((new_total_count) => {
            total_count_changed (new_total_count);
        });

        _folder.updated.connect (() => {
            updated ();
        });
    }
}
