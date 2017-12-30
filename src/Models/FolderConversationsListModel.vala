/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;

public class Envoyer.Models.FolderConversationsListModel : GLib.ListModel, GLib.Object {
    public Folder folder { get; construct set; }
    public Gee.List<Envoyer.Models.ConversationThread> conversation_threads_list;

    public FolderConversationsListModel (Folder folder) {
        Object (folder: folder);
    }

    //@TODO This should listen to signals such as new_conversation(ConversationThread) or delete_conversation(ConversationThread)
    // and translate into the appropriate items_changed signal using the conversation_threads_list

    construct {
        folder.updated.connect(() => {
            var old_size = conversation_threads_list.size;
            conversation_threads_list = folder.threads_list;
            items_changed (0, old_size, conversation_threads_list.size); //@TODO this removes all items and then adds them back when an item changes, make this nicer
        });

        conversation_threads_list = folder.threads_list;
        items_changed (0, conversation_threads_list.size, 0);
    }

    public Object? get_item (uint position) {
        if (conversation_threads_list == null) {
            return null;
        }

        return conversation_threads_list[(int) position];
    }

    public Type get_item_type () {
        return typeof (ConversationThread);
    }

    public uint get_n_items () {
        return conversation_threads_list.size;
    }

    public Object? get_object (uint position)  {
        if (conversation_threads_list == null) {
            return null;
        }

        return conversation_threads_list[(int) position];
    }
}
