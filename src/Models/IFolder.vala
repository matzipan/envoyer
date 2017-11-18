/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public interface Envoyer.Models.IFolder : GLib.Object {
    public abstract bool is_inbox { get; }
    public abstract bool is_trash { get; }
    public abstract bool is_sent { get; }
    public abstract bool is_normal { get; }
    public abstract bool is_spam { get; }
    public abstract bool is_starred { get; }
    public abstract bool is_all_mail { get; }
    public abstract bool is_drafts { get; }
    public abstract bool is_archive { get; }
    public abstract bool is_important { get; }
    public abstract bool is_unified { get; }

    // the type keyword seems to be reserved in Vala
    public abstract Envoyer.Models.IFolder.Type folder_type { get; }

    public abstract uint unread_count { get; }
    public abstract uint total_count { get; }
    public abstract uint recent_count { get; }

    public abstract signal void unread_count_changed (uint new_count);
    public abstract signal void total_count_changed (uint total_count);
    public abstract signal void recent_count_changed (uint recent_count);
    public abstract signal void display_name_changed (string new_name);

    public abstract signal void database_updated ();

    public abstract Gee.List<Envoyer.Models.ConversationThread> threads_list { owned get; }

    public abstract FolderConversationsListModel conversations_list_model { owned get; }

    public abstract string name { get; }

    public enum Type {
        INBOX,
        TRASH,
        SENT,
        NORMAL,
        SPAM,
        STARRED,
        ALL,
        DRAFTS,
        ARCHIVE,
        IMPORTANT;

        public unowned string to_string() {
            switch (this) {
                case INBOX:
                    return "Inbox";

                case TRASH:
                    return "Trash";

                case SENT:
                    return "Sent";

                case NORMAL:
                    return "Normal";

                case SPAM:
                    return "Spam";

                case STARRED:
                    return "Starred";

                case ALL:
                    return "All Mail";

                case DRAFTS:
                    return "Drafts";

                case ARCHIVE:
                    return "Archive";

                case IMPORTANT:
                    return "Important";

                default:
                    assert_not_reached();
            }
        }

        public static Type[] unified_folders() {
            // The order in here dictates the order in the sidebar
            return { INBOX, STARRED, IMPORTANT, DRAFTS, SENT, ARCHIVE, ALL, SPAM, TRASH };
        }
    }

    public static string get_icon_for_folder (Envoyer.Models.IFolder folder) {
        if(folder.is_inbox) {
            return "mail-inbox";
        } else if(folder.is_trash) {
            if(folder.total_count == 0) {
                return "user-trash";
            } else {
                return "user-trash-full";
            }
        } else if(folder.is_sent) {
            return "mail-sent";
        } else if(folder.is_spam) {
            return "edit-flag";
        } else if(folder.is_starred) {
            return "starred";
        } else if(folder.is_drafts) {
            return "folder-documents";
        } else if(folder.is_important) {
            return "mail-mark-important";
        } else if(folder.is_all_mail || folder.is_archive) {
            return "mail-archive";
        } else {
            return "folder-tag";
        }
    }
}
