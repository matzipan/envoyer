/* 
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.ConversationThread : GLib.Object {
    private Envoyer.Models.Folder folder;
    private Camel.MessageInfo _message_info;

    private Camel.MessageInfo message_info { 
        get {
            if (_message_info == null) {
                _message_info = folder.get_message_info(uid);
            }

            return _message_info;
        }
    }
    
    public string subject { get { return (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT); } }
    
    public string uid { get; private set; } //@TODO for now we're fetching all emails, use Camel.FolderThreads instead
    
    public ConversationThread (string uid, Envoyer.Models.Folder folder) {
        this.uid = uid;
        this.folder = folder; 
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    
}