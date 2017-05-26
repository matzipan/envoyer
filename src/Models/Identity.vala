/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.Identity : GLib.Object {
    public void* session { get; construct set; }
    public string name { get; construct set; }
    
    public async Identity (string username, string password, string name) {
        Object(name: name, session: MailCoreInterface.connect (username, password));
    }
    
    public Gee.Collection<Envoyer.Models.Folder> fetch_folders () {
        var folders = MailCoreInterface.fetch_folders (session);
        
        foreach (var item in folders) {
            item.identity = this;
        }
        
        return folders;
    }
    
    public Gee.Collection<Envoyer.Models.ConversationThread> fetch_threads (string name) {
        var messages = MailCoreInterface.fetch_messages (session);
        
        var threader = new Envoyer.Util.ThreadingHelper ();
                
        return threader.process_messages (messages);
    }
}
