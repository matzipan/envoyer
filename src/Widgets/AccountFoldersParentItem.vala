public class Mail.AccountFoldersParentItem : SimpleExpandableItem {
    public AccountFoldersParentItem (Mail.Models.AccountSummary summary) {
        base (summary.identity_source.get_display_name ());
            
        foreach(var folder in summary.folders_list) {  
            add (new Mail.FolderItem (folder));
        }
    }
}