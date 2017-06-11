/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.Identity : GLib.Object {
    public void* imap_session { get; construct set; }
    public void* smtp_session { get; construct set; }
    public string name { get; construct set; }
    
    public async Identity (string username, string password, string name) {
        Object(
            name: name,
            imap_session: MailCoreInterface.imap_connect (username, password),
            smtp_session: MailCoreInterface.smtp_connect (username, password)
        );
    }
    
    public Gee.Collection<Envoyer.Models.Folder> fetch_folders () {
        var folders = MailCoreInterface.imap_fetch_folders (imap_session);
        
        foreach (var item in folders) {
            item.identity = this;
        }
        
        return folders;
    }
    
    public Gee.Collection<Envoyer.Models.ConversationThread> fetch_threads (Envoyer.Models.Folder folder) {
        var messages = MailCoreInterface.imap_fetch_messages (imap_session, folder.name);
        
        foreach (var item in messages) {
            item.identity = this;
            item.folder = folder;
        }
        
        var threader = new Envoyer.Util.ThreadingHelper ();
                
        return threader.process_messages (messages);
    }
    
    public string get_html_for_message (Envoyer.Models.Message message) {
        return MailCoreInterface.imap_get_html_for_message (imap_session, message.folder.name, message); 
    }
}
