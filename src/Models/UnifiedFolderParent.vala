/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.UnifiedFolderParent : Envoyer.Models.IFolder, GLib.Object  {
    private Gee.ArrayList<Envoyer.Models.UnifiedFolderChild> _children = new Gee.ArrayList<Envoyer.Models.UnifiedFolderChild> ();

    public Gee.Collection<Envoyer.Models.UnifiedFolderChild> children {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var children_list_copy = new Gee.ArrayList<Envoyer.Models.UnifiedFolderChild> ();
            children_list_copy.add_all (_children);
            return children_list_copy;
        }
    }

    public bool is_inbox { 
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.INBOX;
        }
    }
    public bool is_trash { 
        get {
            return folder_type == Envoyer.Models.IFolder.Type.TRASH;
        }
    }
    public bool is_outbox { 
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.OUTBOX;
        }
    }
    public bool is_sent { 
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.SENT;
        }
    }
    public bool is_normal { 
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.NORMAL;
        }
    }
    public bool is_spam {
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.SPAM;
        }
    }
    public bool is_starred {
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.STARRED;
        }
    }
    public bool is_all_mail { 
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.ALL;
        }
    }
    public bool is_drafts {
        get { 
            return folder_type == Envoyer.Models.IFolder.Type.DRAFTS;
        }
    }
    public bool is_archive { 
        get {
            return folder_type == Envoyer.Models.IFolder.Type.ARCHIVE;
        }
    }
    public bool is_unified { get { return true; } }

    public uint unread_count { 
        get {
            uint new_unread_count = 0;

            foreach (var child in _children) {
                new_unread_count += child.unread_count;
            }

            return new_unread_count;
        }
    }
    
    public bool is_empty {
        get {
            return _children.is_empty;
        }
    }

    public uint total_count { 
        get {
            uint new_total_count = 0;

            foreach (var child in _children) {
                new_total_count += child.total_count;
            }

            return new_total_count;
        }
    }
    
    private Envoyer.Models.IFolder.Type _folder_type = Envoyer.Models.IFolder.Type.NORMAL;

    public Envoyer.Models.IFolder.Type folder_type { get { return _folder_type; } }

    public string display_name {
        get { 
            return folder_type.to_string ();
        }
    }

    public Gee.LinkedList<Envoyer.Models.ConversationThread> threads_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var threads_list_copy = new Gee.LinkedList<Envoyer.Models.ConversationThread> ();

            foreach (var child in _children) {
                threads_list_copy.add_all (child.threads_list);
            }
            
            //@TODO async and yield
            threads_list_copy.sort ((first, second) => { // sort descendingly
                if(first.time_received > second.time_received) {
                    return -1;
                } else {
                    return 1;
                }
            });

            return threads_list_copy;
        }
    }

    public signal void child_added (Envoyer.Models.UnifiedFolderChild new_child);
    public signal void child_removed (Envoyer.Models.UnifiedFolderChild new_child); //@TODO
    
    public UnifiedFolderParent (Envoyer.Models.IFolder.Type folder_type) {
        _folder_type = folder_type;
    }

    public void add(Envoyer.Models.UnifiedFolderChild child) {
        _children.add (child);
        child.unread_count_changed.connect ((new_unread_count) => {
                unread_count_changed (new_unread_count);
            });
        child.total_count_changed.connect ((new_total_count) => {
                total_count_changed (new_total_count);
            });
        child_added (child);
    }

    public Camel.MessageInfo get_message_info (string uid) {
        foreach (var child in _children) {
            var message_info = child.get_message_info (uid);
            
            if(message_info != null) {
                return message_info;
            }
        }
        
        assert_not_reached ();
    }
    
    public Camel.MimeMessage get_mime_message (string uid) {
        foreach (var child in _children) {
            var message_info = child.get_mime_message (uid);
            
            if(message_info != null) {
                return message_info;
            }
        }
        
        assert_not_reached ();
    }
}