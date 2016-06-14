public class Mail.UnifiedFolderChildItem : Mail.FolderItem {
    public signal void unread_count_changed (uint new_count);

    public UnifiedFolderChildItem (Mail.Models.UnifiedFolderChild folder) {
        base (folder);

        connect_signals ();
    }
    
    private void connect_signals () {
        folder.unread_count_changed.connect (new_count => { unread_count_changed(new_count); });
    }
}