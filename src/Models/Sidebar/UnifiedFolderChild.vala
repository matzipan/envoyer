/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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

        _folder.database_updated.connect (() => {
            database_updated ();
        });
    }
}
