/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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

    public Gee.Collection <Address> display_addresses {
        owned get {
            //@TODO order the addresses
            var addresses = new Gee.LinkedList <Address> (null);

            var unique_addresses = new Gee.HashMap <string, Address>();

            //@TODO replace current acount with "Me"

            foreach (var message_instance in _messages_list) {
                unique_addresses[message_instance.from.to_string ()] = message_instance.from;
            }

            addresses.add_all (unique_addresses.values);

            return addresses;
        }
    }

    public time_t time_received {
        owned get {
            return _messages_list[0].time_received;
        }
    }

    public GLib.DateTime datetime_received {
        owned get {
            return _messages_list[0].datetime_received;
        }
    }

    public string subject { get { return _messages_list[0].subject; } }

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

        _messages_list.sort ((first, second) => { // sort descendingly
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
