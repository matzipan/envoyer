public class Mail.Models.UnifiedFolderChild : Mail.Models.IFolder, GLib.Object {
    private E.Source identity_source; //@TODO write a wrapper model for E.Source
    private Mail.Models.Folder _folder;

    public bool is_inbox { get { return _folder.is_inbox; } }
    public bool is_trash { get { return _folder.is_trash; } }
    public bool is_outbox { get { return _folder.is_outbox; } }
    public bool is_sent { get { return _folder.is_sent; } }
    public bool is_normal { get { return _folder.is_normal; } }
    public bool is_junk { get { return _folder.is_junk; } }
    public bool is_starred { get { return _folder.is_starred; } }
    public bool is_unified { get { return _folder.is_unified; } }

    public uint unread_count { get { return _folder.unread_count; } }

    public Gee.LinkedList<Mail.Models.ConversationThread> threads_list { get { return _folder.threads_list; } }

    public string display_name { get { return identity_source.get_display_name (); } }

    public UnifiedFolderChild (Mail.Models.Folder folder, E.Source identity_source) {
        this.identity_source = identity_source;
        _folder = folder;

        connect_signals ();
    }

    public void connect_signals () {
        // @TODO watch for identity_source display_name change
    }
    
    public Camel.MessageInfo get_message_info (string uid) { return _folder.get_message_info(uid); }
}