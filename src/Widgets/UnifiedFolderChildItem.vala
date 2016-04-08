public class Mail.UnifiedFolderChildItem : FolderItem {
    public UnifiedFolderChildItem (Camel.Folder folder, Mail.Models.AccountSummary summary) {
        base (folder, summary.identity_source.get_display_name ());
    }
}