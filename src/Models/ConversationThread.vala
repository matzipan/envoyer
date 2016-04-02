public class Mail.Models.ConversationThread {
    private Camel.Folder folder;
    private string _uid; //@TODO for now we're fetching all emails, use Camel.FolderThreads instead
    private Camel.MessageInfo _message_info;
    
    private Camel.MessageInfo message_info { 
        get {
            if (_message_info == null) {
                _message_info = folder.get_message_info(uid);
            }
            
            return _message_info;
        }
    }
    
    public string uid { get { return _uid; } }
    
    public ConversationThread (string uid, Camel.Folder folder) {
        this._uid = uid;
        this.folder = folder; 
    }
    
    public string get_subject() {
        return (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT);
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    public static Gee.LinkedList<Mail.Models.ConversationThread> get_threads_list (Camel.Folder folder) {  //@TODO async 
        var threads_list = new Gee.LinkedList<Mail.Models.ConversationThread> (null);
                
        /*folder.get_summary().foreach((message_info) => { //@TODO decide if to use this or not
                //message("- %s", (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT));
                message_info.dump();
            });*/
        
        folder.get_uids().foreach((uid) => {
            threads_list.add(new Mail.Models.ConversationThread(uid, folder));
        });
                
        return threads_list;     
    }
}