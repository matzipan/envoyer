/* 
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.AccountSummary : GLib.Object {
    private bool _expanded = true; //@TODO persist this
    
    //@TODO maybe the summary should have properties for each of the special folders: inbox, sent, drafts, etc.

    public E.Source identity_source { get; private set; }
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
    
    public AccountSummary (Camel.Service service) {
        identity_source = Envoyer.session.get_identity_source_for_service (service);

        var folders = ((Camel.OfflineStore) service).get_folders_bag ().list ();
        folders.foreach((object) => {
            _folder_list.add (new Envoyer.Models.Folder((Camel.Folder) object, ((Camel.OfflineStore) service)));
        });

    }
}
