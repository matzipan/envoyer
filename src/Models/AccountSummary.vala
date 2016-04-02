public class Mail.Models.AccountSummary {
    public E.Source identity_source;
    public Gee.List<Camel.Folder> folder_list;
    
    private bool _expanded = true; //@TODO persist this
    public bool expanded {
        get { return _expanded; }
        set { _expanded = value; }
    }
    
    public AccountSummary (E.Source identity_source) {
        this.identity_source = identity_source;
        folder_list = new Gee.LinkedList<Camel.Folder> (null);
    }
    
    public static Gee.LinkedList<Mail.Models.AccountSummary> get_summaries_list () {  //@TODO async 
        var summaries_list = new Gee.LinkedList<Mail.Models.AccountSummary> (null);
        
        backend.get_services().foreach((service) => {
            var account_summary = new Mail.Models.AccountSummary (Mail.backend.get_identity_source_for_service (service));
        
            var folders = ((Camel.OfflineStore) service).folders.list();
            folders.foreach((object) => {   
                account_summary.folder_list.add ((Camel.Folder) object);
            });
            
            summaries_list.add(account_summary);
        });   
        
        return summaries_list;     
    }
}