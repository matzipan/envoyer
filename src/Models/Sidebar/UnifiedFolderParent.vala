/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;

public class Envoyer.Models.Sidebar.UnifiedFolderParent : IFolder, Basalt.Widgets.SidebarExpandableRowModel  {
    public Gee.List <UnifiedFolderChild> folder_children {
        owned get {
            return (Gee.List <UnifiedFolderChild>) children.full_list;
        }
    }

    public bool is_inbox {
        get {
            return folder_type == IFolder.Type.INBOX;
        }
    }
    public bool is_trash {
        get {
            return folder_type == IFolder.Type.TRASH;
        }
    }
    public bool is_sent {
        get {
            return folder_type == IFolder.Type.SENT;
        }
    }
    public bool is_normal {
        get {
            return folder_type == IFolder.Type.NORMAL;
        }
    }
    public bool is_spam {
        get {
            return folder_type == IFolder.Type.SPAM;
        }
    }
    public bool is_starred {
        get {
            return folder_type == IFolder.Type.STARRED;
        }
    }
    public bool is_all_mail {
        get {
            return folder_type == IFolder.Type.ALL;
        }
    }
    public bool is_drafts {
        get {
            return folder_type == IFolder.Type.DRAFTS;
        }
    }
    public bool is_archive {
        get {
            return folder_type == IFolder.Type.ARCHIVE;
        }
    }
    public bool is_important {
        get {
            return folder_type == IFolder.Type.IMPORTANT;
        }
    }
    public bool is_unified { get { return true; } }

    public uint unread_count {
        get {
            uint new_unread_count = 0;

            foreach (var child in folder_children) {
                new_unread_count += child.unread_count;
            }

            return new_unread_count;
        }
    }

    public bool is_empty {
        get {
            return folder_children.is_empty;
        }
    }

    public uint total_count {
        get {
            uint new_total_count = 0;

            foreach (var child in folder_children) {
                new_total_count += child.total_count;
            }

            return new_total_count;
        }
    }


    public uint recent_count {
        get {
            uint new_recent_count = 0;

            foreach (var child in folder_children) {
                new_recent_count += child.recent_count;
            }

            return new_recent_count;
        }
    }

    private IFolder.Type _folder_type = IFolder.Type.NORMAL;

    public IFolder.Type folder_type { get { return _folder_type; } }

    public string name {
        get {
            return folder_type.to_string ();
        }
    }

    public Gee.List <ConversationThread> threads_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var threads_list_copy = new Gee.LinkedList <ConversationThread> ();

            foreach (var child in folder_children) {
                threads_list_copy.add_all (child.threads_list);
            }

            //@TODO async and yield
            threads_list_copy.sort ((first, second) => { // sort descendingly
                /*if(first.time_received > second.time_received) {
                    return -1;
                } else {
                    return 1;
                }*/
                return 1;
            });

            return threads_list_copy;
        }
    }

    //@TODO unify this and make it work with multiple accounts
    public FolderConversationsListModel conversations_list_model { owned get { return folder_children[0].conversations_list_model; } }

    public UnifiedFolderParent (IFolder.Type folder_type) {
        base (folder_type.to_string (), false);

        _folder_type = folder_type;

        //@TODO listen to total_count_changed signal and change the icon accordingly
        icon_name = IFolder.get_icon_for_folder (this);

        connect_signals ();
    }

    private void connect_signals () {
        children.item_added.connect (handle_child_added);
    }

    private void handle_child_added (Basalt.Widgets.SidebarRowModel child) {
        assert (child is UnifiedFolderChild);

        var unified_child = (UnifiedFolderChild) child;

        unified_child.unread_count_changed.connect ((new_unread_count) => {
            unread_count_changed (new_unread_count);
        });

        unified_child.total_count_changed.connect ((new_total_count) => {
            total_count_changed (new_total_count);
        });
        
        unified_child.database_updated.connect (() => {
            database_updated ();
        });
    }
}
