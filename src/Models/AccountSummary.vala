public class Mail.Models.AccountSummary {
    public E.Source identity_source;
    public Gee.Collection<Mail.Models.Folder> folders_list {
        owned get {
            // Create a copy of the children so that it's safe to iterate it
            // (e.g. by using foreach) while removing items.
            var folders_list_copy = new Gee.ArrayList<Mail.Models.Folder> ();
            folders_list_copy.add_all (_folder_list);
            return folders_list_copy;
        }
    }
    
    public Gee.ArrayList<Mail.Models.Folder> _folder_list; //@TODO make this private and use constructor to set _folder_list
    
    public Mail.Models.Folder inbox_folder; // make private
    
    private bool _expanded = true; //@TODO persist this
    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }
    
    public AccountSummary (E.Source identity_source) {
        this.identity_source = identity_source;
        _folder_list = new Gee.ArrayList<Mail.Models.Folder> (null); 
    }
    
    //@TODO transform into getter method 
    public static Gee.Collection<Mail.Models.AccountSummary> get_summaries_list () {  //@TODO async 
        var summaries_list = new Gee.ArrayList<Mail.Models.AccountSummary> (null);
        
        Mail.session.get_services().foreach((service) => {
            var account_summary = new Mail.Models.AccountSummary (Mail.session.get_identity_source_for_service (service));
        
            var folders = ((Camel.OfflineStore) service).folders.list ();
            folders.foreach((object) => {   
                var folder = new Mail.Models.Folder((Camel.Folder) object, ((Camel.OfflineStore) service));
                
                if(folder.is_inbox) {
                    account_summary.inbox_folder = folder;
                } else {
                    account_summary._folder_list.add (folder); //@TODO use constructor
                }
                
            });
            
            summaries_list.add(account_summary);
        });   
        
        return summaries_list;     
    }
}