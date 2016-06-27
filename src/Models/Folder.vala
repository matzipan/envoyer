/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.Folder : Envoyer.Models.IFolder, GLib.Object {
    private Camel.FolderInfo folder_info;
    private Camel.Folder folder;

    public bool is_inbox { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_INBOX; } }
    public bool is_trash { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_TRASH; } }
    public bool is_outbox { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_OUTBOX; } }
    public bool is_sent { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_SENT; } }
    public bool is_normal { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_NORMAL; } }
    public bool is_spam { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_JUNK; } }
    public bool is_starred { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_FLAGGED; } }
    public bool is_all_mail { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_ALL; }  }
    public bool is_important { get { return (folder_info.flags & Camel.FOLDER_TYPE_MASK) == Camel.FolderInfoFlags.TYPE_IMPORTANT; } }
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
            
            if (is_important) {
                return Envoyer.Models.IFolder.Type.IMPORTANT;
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

    private Gee.LinkedList<Envoyer.Models.ConversationThread> _threads_list; 
    
    //@TODO trigger unread_count_changed
    //@TODO trigger total_count_changed

    public Gee.LinkedList<Envoyer.Models.ConversationThread> threads_list { 
        get {  //@TODO async
            if(_threads_list == null) {
                _threads_list = new Gee.LinkedList<Envoyer.Models.ConversationThread> (null);
                
                folder.get_uids().foreach((uid) => {
                    _threads_list.add(new Envoyer.Models.ConversationThread(uid, this));
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