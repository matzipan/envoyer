public class Mail.AccountFoldersParentItem : Mail.SimpleExpandableItem {
    public AccountFoldersParentItem (Mail.Models.AccountSummary summary) {
        //@TODO this logic should be moved to a model
        base (summary.identity_source.get_display_name ());

        foreach (var folder in summary.folders_list) {
            if (folder.is_normal) {
                add (new Mail.FolderItem (folder));
            }
        }
    }
}