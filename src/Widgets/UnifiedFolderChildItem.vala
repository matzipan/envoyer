public class Mail.UnifiedFolderChildItem : FolderItem {
    public UnifiedFolderChildItem (Mail.Models.Folder folder, Mail.Models.AccountSummary summary) {
        base (folder, summary.identity_source.get_display_name ());
    }
}