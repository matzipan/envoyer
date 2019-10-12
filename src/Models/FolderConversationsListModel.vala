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
