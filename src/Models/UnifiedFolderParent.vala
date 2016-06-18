public class Mail.Models.UnifiedFolderParent : Mail.Models.IFolder, GLib.Object  {
    private string name;
    private Gee.ArrayList<Mail.Models.UnifiedFolderChild> _children = new Gee.ArrayList<Mail.Models.UnifiedFolderChild> ();
    
    public Gee.Collection<Mail.Models.UnifiedFolderChild> children {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var children_list_copy = new Gee.ArrayList<Mail.Models.UnifiedFolderChild> ();
            children_list_copy.add_all (_children);
            return children_list_copy;
        }
    }

    public bool is_inbox { get { return false; } } //@TODO maybe decide this at runtime, and also decide name at run-time
    public bool is_trash { get { return false; } }
    public bool is_outbox { get { return false; } }
    public bool is_sent { get { return false; } }
    public bool is_normal { get { return false; } }
    public bool is_junk { get { return false; } }
    public bool is_starred { get { return false; } }
    public bool is_all_mail { get { return false; } }
    public bool is_important { get { return false; } }
    public bool is_drafts { get { return false; } }
    public bool is_archive { get { return false; } }
    public bool is_unified { get { return true; } }

    public uint unread_count { 
        get {
            uint new_unread_count = 0;

            foreach (var child in children) {
                new_unread_count += child.unread_count;
            }

            return new_unread_count;
        }
    }
    
    public uint total_count { 
        get {
            uint new_total_count = 0;

            foreach (var child in children) {
                new_total_count += child.total_count;
            }

            return new_total_count;
        }
    }


    public Gee.LinkedList<Mail.Models.ConversationThread> threads_list { get { return null; } } //@TODO merge this from chidlren

    public string display_name { get { return name; } }
    
    public signal void child_added (Mail.Models.UnifiedFolderChild new_child);
    public signal void child_removed (Mail.Models.UnifiedFolderChild new_child); //@TODO

    public UnifiedFolderParent (string name) {
        this.name = name;
    }

    public void add(Mail.Models.UnifiedFolderChild child) {
        _children.add (child);
        child.unread_count_changed.connect ((new_unread_count) => {
                unread_count_changed (new_unread_count);
            });
        child.total_count_changed.connect ((new_total_count) => {
                total_count_changed (new_total_count);
            });
        child_added (child);
    }

    public Camel.MessageInfo get_message_info (string uid) { return null; } //@TODO search through the children

}