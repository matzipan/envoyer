/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

 using Envoyer.Globals.Application;

public struct Envoyer.FolderStruct {
    int unseen_count;
    int message_count;
    int recent_count;
    int uid_next;
    int uid_validity;
    int64 highest_modification_sequence;
}

public class Envoyer.Models.Folder : Envoyer.Models.IFolder, Basalt.Widgets.SidebarRowModel {
    private Envoyer.FolderStruct data;
    public int flags { get; private set; }
    public Envoyer.Models.Identity identity;

    // It appears that MailCore does the same check for name == "INBOX"
    public bool is_inbox { get { return (flags & (1 << 4)) != 0 || name == "INBOX"; } }
    public bool is_sent { get { return (flags & (1 << 5)) != 0; } }
    public bool is_starred { get { return (flags & (1 << 6)) != 0; } }
    public bool is_all_mail { get { return (flags & (1 << 7)) != 0; } }
    public bool is_trash { get { return (flags & (1 << 8)) != 0; } }
    public bool is_drafts { get { return (flags & (1 << 9)) != 0; } }
    public bool is_spam { get { return (flags & (1 << 10)) != 0; } }
    public bool is_important { get { return (flags & (1 << 11)) != 0; } }
    public bool is_archive { get { return (flags & (1 << 12)) != 0; } }
    // is_normal is linked to IMAPFolderFlagFolderTypeMask in MailCore. Perhaps find a more elegant solution...
    public bool is_normal { get { return !is_inbox && !is_trash && !is_sent && !is_spam && !is_starred && !is_important && !is_all_mail && !is_drafts && !is_archive; } }
    public bool is_unified { get { return false; } }

    public Envoyer.Models.IFolder.Type folder_type {
        get {
            if (is_inbox) {
                return Envoyer.Models.IFolder.Type.INBOX;
            }

            if (is_trash) {
                return Envoyer.Models.IFolder.Type.TRASH;
            }

            if (is_sent) {
                return Envoyer.Models.IFolder.Type.SENT;
            }

            if (is_normal) {
                return Envoyer.Models.IFolder.Type.NORMAL;
            }

            if (is_spam) {
                return Envoyer.Models.IFolder.Type.SPAM;
            }

            if (is_starred) {
                return Envoyer.Models.IFolder.Type.STARRED;
            }

            if (is_all_mail) {
                return Envoyer.Models.IFolder.Type.ALL;
            }

            if (is_drafts) {
                return Envoyer.Models.IFolder.Type.DRAFTS;
            }

            if (is_archive) {
                return Envoyer.Models.IFolder.Type.ARCHIVE;
            }

            if (is_important) {
                return Envoyer.Models.IFolder.Type.IMPORTANT;
            }

            assert_not_reached ();
        }

    }

    public uint highest_uid {
        get {
            return database.get_highest_uid_for_folder (this);
        }
    }

    public uint unread_count { get { return data.unseen_count; } }
    public uint total_count { get { return data.message_count; } }
    public uint recent_count { get { return data.recent_count; } }

    //@TODO trigger unread_count_changed
    //@TODO trigger total_count_changed

    public Gee.List<Envoyer.Models.ConversationThread> threads_list {
        owned get {  //@TODO async
            var threads_list_copy = new Gee.LinkedList<Envoyer.Models.ConversationThread> (null);

            foreach (var thread in identity.get_threads (this)) {
                if (thread.deleted && is_trash || !thread.deleted) {
                    threads_list_copy.add (thread);
                }
            }

            threads_list_copy.sort ((first, second) => { // sort descendingly
                if(first.time_received > second.time_received) {
                    return -1;
                } else {
                    return 1;
                }
            });

            return threads_list_copy;
        }
    }

    public FolderConversationsListModel conversations_list_model {
        owned get {
            return new FolderConversationsListModel (this);
        }
    }

    private string _name;
    public string name { get { return _name; } }

    public Folder(string name, int flags, Envoyer.FolderStruct data) {
        base (name.dup ());

        _name = name.dup ();
        this.flags = flags;
        this.data = data;
        icon_name = IFolder.get_icon_for_folder (this);
    }

    construct {
        application.folder_updated.connect ((folder_name) => {
            if (folder_name == name) {
                updated ();
            }
        });
    }
}
