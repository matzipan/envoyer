/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.ConversationThread : GLib.Object {
    private Gee.ArrayList <Envoyer.Models.Message> _messages_list = new Gee.ArrayList <Envoyer.Models.Message> ();

    //@TODO concatenate addresses
    // @TODO if this is to slow, it might be worth doing memoization
    public Gee.Collection <Envoyer.Models.Message> messages_list {
        owned get {  //@TODO async
            var messages_list_copy = new Gee.LinkedList<Envoyer.Models.Message> (null);

            messages_list_copy.add_all (_messages_list);
            
            return messages_list_copy;
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
    
    public ConversationThread.from_container (Envoyer.Models.Container container) {
        if (container.message != null) {
            _messages_list.add (container.message);
        }
        
        foreach (var child_message in container.children) {
            _messages_list.add (child_message.message);
        }
        
        _messages_list.sort ((first, second) => { // sort descendingly
            if(first.time_received > second.time_received) {
                return -1;
            } else {
                return 1;
            }
            
            return 1;
        });
        
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    
}
