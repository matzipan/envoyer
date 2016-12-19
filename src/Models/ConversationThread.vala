/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.ConversationThread : GLib.Object {
    private Envoyer.Models.Folder folder;
    private Camel.MessageInfo message_info { get { return thread_node.message; } }
    private Camel.FolderThreadNode thread_node;

    // @TODO if this is to slow, it might be worth doing memoization
    public Gee.LinkedList<Envoyer.Models.Message> messages {
        owned get {  //@TODO async
            var messages_list_copy = new Gee.LinkedList<Envoyer.Models.Message> (null);

            Camel.FolderThreadNode? node = thread_node;

            while (node != null) {
                messages_list_copy.add(new Envoyer.Models.Message(node, folder));

                node = (Camel.FolderThreadNode?) node.child;
            }

            return messages_list_copy;
        }
    }
    
    public GLib.DateTime datetime { //@TODO right now this competes with time_received, unify
        owned get {
            return new GLib.DateTime.from_unix_utc (time_received).to_local (); //@TODO how does this work with DATE_SENT
        } 
    }

    public int64 time_received { //@TODO right now this competes with datetime, unify
        get {
            return message_info.get_date_received ();
        }
    }

    public int64 time_sent { //@TODO what does thsi mean?
        get {
            return message_info.get_date_sent ();
        }
    }

    public string subject { get { return message_info.get_subject (); } }

    public ConversationThread (Camel.FolderThreadNode thread_node, Envoyer.Models.Folder folder) {
        this.thread_node = thread_node;
        this.folder = folder;
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    
}
