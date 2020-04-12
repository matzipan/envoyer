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

public class Envoyer.Models.ConversationThread : GLib.Object {
    private Gee.ArrayList <Message> _messages_list = new Gee.ArrayList <Message> ();

    public Gee.Collection <Message> messages_list {
        owned get {  //@TODO async
            var messages_list_copy = new Gee.LinkedList <Message> (null);

            messages_list_copy.add_all (_messages_list);

            return messages_list_copy;
        }
    }
    
    public Gee.List <string> message_ids_list {
        owned get {
            var message_ids_list = new Gee.LinkedList <string> (null);

            foreach (var message_instance in _messages_list) {
                message_ids_list.add (message_instance.id);
            }
            
            return message_ids_list;
        }
    }
    
    public bool has_non_inline_attachments {
        get {
            foreach (var message_instance in _messages_list) {
                if (message_instance.non_inline_attachments.size != 0) {
                    return true;
                }
            }

            return false;
        }
    }
    
    public Message last_received_message {
        owned get {
            // Assuming _messages_list is sorted descendingly by time of receipt
            return _messages_list[0];
        }
    }

    public Gee.Collection <Address> display_addresses {
        owned get {
            //@TODO order the addresses
            var addresses = new Gee.LinkedList <Address> (null);

            var unique_addresses = new Gee.HashMap <string, Address>();

            foreach (var message_instance in _messages_list) {
                unique_addresses[message_instance.from.to_string ()] = message_instance.from;
            }

            addresses.add_all (unique_addresses.values);

            return addresses;
        }
    }

    public time_t time_received {
        owned get {
            // Assuming _messages_list is sorted descendingly by time of receipt
            return _messages_list[0].time_received;
        }
    }

    public GLib.DateTime datetime_received {
        owned get {
            // Assuming _messages_list is sorted descendingly by time of receipt
            return _messages_list[0].datetime_received;
        }
    }

    public string subject { 
        // The subject line is given by the oldest message in the thread. Assuming _messages_list is sorted descendingly by time of receipt
        get { return _messages_list[_messages_list.size - 1].subject; } 
    }

    public Folder folder { 
        // We're assuming all messages in the thread are in the same folder
        get { return _messages_list[0].folder; } 
    }

    // If there's at least one unseen message in the thread, return false
    public bool seen {
        get {
            foreach (var current_message in _messages_list) {
                if (!current_message.seen) {
                    return false;
                }
            }

            return true;
        }
    }

    // If there's at least one starred message in the thread, return true
    public bool flagged {
        get {
            foreach (var current_message in _messages_list) {
                if (current_message.flagged) {
                    return true;
                }
            }

            return false;
        }
    }

    // If there's at least one message which is not deleted in the thread, return false
    public bool deleted {
        get {
            foreach (var current_message in _messages_list) {
                if (!current_message.deleted) {
                    return false;
                }
            }

            return true;
        }
    }

    public ConversationThread.from_container (Envoyer.Util.ThreadingContainer container) {
        if (container.message != null) {
            _messages_list.add (container.message);
        }

        walk_children_containers (container);

        // Sort the messages descendingly by time received
        _messages_list.sort ((first, second) => {
            if(first.time_received > second.time_received) {
                return -1;
            } else {
                return 1;
            }

            return 1;
        });

    }

    private void walk_children_containers (Envoyer.Util.ThreadingContainer container) {
        foreach (var child_container in container.children) {
            walk_children_containers (child_container);

            _messages_list.add (child_container.message);
        }
    }

    public bool is_important() {
        return false;
    }

    public void get_tags() {
        //@TODO
    }


}
