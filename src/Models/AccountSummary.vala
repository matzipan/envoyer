/* 
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.AccountSummary : GLib.Object {
    private bool _expanded = true; //@TODO persist this
    
    //@TODO maybe the summary should have properties for each of the special folders: inbox, sent, drafts, etc.

    public Identity identity { get; construct set; }
    
    public Gee.Collection<Envoyer.Models.Folder> folders_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var folders_list_copy = new Gee.ArrayList<Envoyer.Models.Folder> ();
            folders_list_copy.add_all (_folder_list);
            return folders_list_copy;
        }
    }

    private Gee.ArrayList<Envoyer.Models.Folder> _folder_list = new Gee.ArrayList<Envoyer.Models.Folder> (null);

    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }
    
    public AccountSummary (Envoyer.Models.Identity identity) {
        Object (identity: identity);
                
        _folder_list.add_all (identity.fetch_folders ());
    }
}
