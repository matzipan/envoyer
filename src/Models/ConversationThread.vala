public class Mail.Models.ConversationThread {
    private Mail.Models.Folder folder;
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
    
    public string subject { get { return (string) message_info.get_ptr(Camel.MessageInfoField.SUBJECT); } }
    
    public string uid { get { return _uid; } }
    
    public ConversationThread (string uid, Mail.Models.Folder folder) {
        this._uid = uid;
        this.folder = folder; 
    }
    
    public bool is_important() {
        return false;
    }
    
    public void get_tags() {
        //@TODO
    }
    
    
}