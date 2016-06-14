public interface Mail.Models.IFolder : GLib.Object {
    public abstract bool is_inbox { get; }
    public abstract bool is_trash { get; }
    public abstract bool is_outbox { get; }
    public abstract bool is_sent { get; }
    public abstract bool is_normal { get; }
    public abstract bool is_junk { get; }
    public abstract bool is_starred { get; }
    public abstract bool is_unified { get; }

    public abstract uint unread_count { get; }

    public abstract signal void unread_count_changed (uint new_count);
    public abstract signal void display_name_changed (string new_name);

    //@TODO all_mail_folder
    //@TODO important_folder
    //@TODO starred_folder
    //@TODO drafts_folder
    //@TODO archive_folder

    public abstract Gee.LinkedList<Mail.Models.ConversationThread> threads_list { get; }

    public abstract string display_name { get; }
    
    public abstract Camel.MessageInfo get_message_info (string uid);
}