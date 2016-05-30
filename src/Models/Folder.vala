public class Mail.Models.Folder {
    private Camel.FolderInfo folder_info;
    private Camel.Folder folder;
    
    public bool is_inbox { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_INBOX) != 0; } }
    public bool is_trash { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_TRASH) != 0; } }
    public bool is_outbox { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_OUTBOX) != 0; } }
    public bool is_sent { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_SENT) != 0; } }
    public bool is_normal { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_NORMAL) != 0; } }
    public bool is_junk { get { return (folder_info.flags & Camel.FolderInfoFlags.TYPE_JUNK) != 0; } }
    public bool is_starred { get { return (folder_info.flags & Camel.FolderInfoFlags.FLAGGED) != 0; } }
    
    public uint unread_count { get { return folder.summary.unread_count; } }
    
    //@TODO all_mail_folder
    //@TODO important_folder
    //@TODO starred_folder
    //@TODO drafts_folder
    //@TODO archive_folder
    
    private Gee.LinkedList<Mail.Models.ConversationThread> _threads_list; 
    
    public Gee.LinkedList<Mail.Models.ConversationThread> threads_list { 
        get {  //@TODO async
            if(_threads_list == null) {
                _threads_list = new Gee.LinkedList<Mail.Models.ConversationThread> (null);
                
                folder.get_uids().foreach((uid) => {
                    _threads_list.add(new Mail.Models.ConversationThread(uid, this));
                });
            }
                        
            return _threads_list;     
        }
    }
    
    public string display_name { get { return folder.get_display_name (); } }

    public Folder(Camel.Folder folder, Camel.OfflineStore service) {
        this.folder = folder;
        folder_info = service.get_folder_info_sync(folder.dup_full_name(), Camel.StoreGetFolderInfoFlags.RECURSIVE);        
    }
    
    public Camel.MessageInfo get_message_info (string uid) {
        return folder.get_message_info(uid);
    }

}