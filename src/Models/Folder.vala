/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.Folder : Envoyer.Models.IFolder, GLib.Object {
    private Camel.FolderInfo folder_info;
    private Camel.Folder folder;
    private Camel.FolderThread thread;

    public bool is_inbox { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_INBOX; } }
    public bool is_trash { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_TRASH; } }
    public bool is_outbox { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_OUTBOX; } }
    public bool is_sent { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_SENT; } }
    // The extra check for is_starred in is_normal is needed because we wanted to avoid breaking API changes in EDS
    public bool is_normal { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_NORMAL && !is_starred; } }
    public bool is_spam { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_JUNK; } }
    public bool is_starred { get { return (folder_info.flags & Camel.FolderInfoFlags.FLAGGED) != 0; } }
    public bool is_all_mail { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_ALL; }  }
    public bool is_drafts { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_DRAFTS; } }
    public bool is_archive { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_ARCHIVE; } }
    public bool is_unified { get { return false; } }
    
    public Envoyer.Models.IFolder.Type folder_type {
        get {
            if (is_inbox) {
                return Envoyer.Models.IFolder.Type.INBOX;
            }

            if (is_trash) {
                return Envoyer.Models.IFolder.Type.TRASH;
            }
            
            if (is_outbox) {
                return Envoyer.Models.IFolder.Type.OUTBOX;
            }

            if (is_sent) {
                return Envoyer.Models.IFolder.Type.SENT;
            }
            
            if (is_normal) {
                return Envoyer.Models.IFolder.Type.NORMAL;
            }
            
            if (is_spam) {
                return Envoyer.Models.IFolder.Type.SPAM;
            }
            
            if (is_starred) {
                return Envoyer.Models.IFolder.Type.STARRED;
            }
            
            if (is_all_mail) {
                return Envoyer.Models.IFolder.Type.ALL;
            }
            
            if (is_drafts) {
                return Envoyer.Models.IFolder.Type.DRAFTS;
            }

            if (is_archive) {
                return Envoyer.Models.IFolder.Type.ARCHIVE;
            }

            assert_not_reached ();
        }
    
    }

    public uint unread_count { get { return folder_info.unread; } }
    public uint total_count { get { return folder_info.total; } }
    
    //@TODO trigger unread_count_changed
    //@TODO trigger total_count_changed

    public Gee.LinkedList<Envoyer.Models.ConversationThread> threads_list { 
        owned get {  //@TODO async
            var threads_list_copy = new Gee.LinkedList<Envoyer.Models.ConversationThread> (null);
            
            var tree = thread.tree;

            while (tree != null) {
                threads_list_copy.add(new Envoyer.Models.ConversationThread(*tree, this));

                tree = tree.next;
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

    public string display_name { get { return folder.get_display_name (); } }
    

    public Folder(Camel.Folder folder, Camel.OfflineStore service) {
        this.folder = folder;
        
        //folder.refresh_info_sync(); //@TODO
        
        folder_info = service.get_folder_info_sync (folder.dup_full_name(), Camel.StoreGetFolderInfoFlags.RECURSIVE);
        thread = new Camel.FolderThread (folder, folder.get_uids(), true); //@TODO I guess free thread?
        

    }

    public Camel.MessageInfo get_message_info (string uid) {
        return folder.get_message_info (uid);
    }
    
    public Camel.MimeMessage get_mime_message (string uid) {
        //folder.synchronize_message_sync (uid); //@TODO async? also, this should probably happen in a more batch manner*/
        
        return folder.get_message_sync (uid); //@TODO async?
    }
}
