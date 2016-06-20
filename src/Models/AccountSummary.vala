public class Mail.Models.AccountSummary : GLib.Object {
    private bool _expanded = true; //@TODO persist this
    
    //@TODO maybe the summary should have properties for each of the special folders: inbox, sent, drafts, etc.

    public E.Source identity_source { get; private set; }
    public Gee.Collection<Mail.Models.Folder> folders_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var folders_list_copy = new Gee.ArrayList<Mail.Models.Folder> ();
            folders_list_copy.add_all (_folder_list);
            return folders_list_copy;
        }
    }

    private Gee.ArrayList<Mail.Models.Folder> _folder_list = new Gee.ArrayList<Mail.Models.Folder> (null);

    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }
    
    public AccountSummary (Camel.Service service) {
        identity_source = Mail.session.get_identity_source_for_service (service);

        var folders = ((Camel.OfflineStore) service).folders.list ();
        folders.foreach((object) => {
            _folder_list.add (new Mail.Models.Folder((Camel.Folder) object, ((Camel.OfflineStore) service)));
        });

    }
}