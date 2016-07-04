/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.ConversationThread : GLib.Object {
    private Envoyer.Models.Folder folder;
    private Camel.MessageInfo message_info { get; private set; }

    public int64 time_received {
        get {
            var tm = message_info.get_time (Camel.MessageInfoField.DATE_RECEIVED);

            return tm;
        }
    }

    public int64 time_sent {
        get {
            var tm = message_info.get_time (Camel.MessageInfoField.DATE_SENT);
            
            return tm;
        }
    }

    public string subject { get { return (string) message_info.get_ptr (Camel.MessageInfoField.SUBJECT); } }
    
    public ConversationThread (Camel.MessageInfo message_info, Envoyer.Models.Folder folder) {
        this.message_info = message_info;
        this.folder = folder;
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    
}