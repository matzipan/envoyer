public interface Mail.Models.IFolder : GLib.Object {
    public abstract bool is_inbox { get; }
    public abstract bool is_trash { get; }
    public abstract bool is_outbox { get; }
    public abstract bool is_sent { get; }
    public abstract bool is_normal { get; }
    public abstract bool is_junk { get; }
    public abstract bool is_starred { get; }
    public abstract bool is_all_mail { get; }
    public abstract bool is_important { get; }
    public abstract bool is_drafts { get; }
    public abstract bool is_archive { get; }
    public abstract bool is_unified { get; }

    public abstract uint unread_count { get; }
    public abstract uint total_count { get; }

    public abstract signal void unread_count_changed (uint new_count);
    public abstract signal void total_count_changed (string new_name);
    public abstract signal void display_name_changed (string new_name);

    public abstract Gee.LinkedList<Mail.Models.ConversationThread> threads_list { get; }

    public abstract string display_name { get; }
    
    public abstract Camel.MessageInfo get_message_info (string uid);
}