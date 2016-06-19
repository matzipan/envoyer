public class Mail.FolderItem : Gtk.ListBoxRow {
    private Gtk.Grid grid;
    private Mail.FolderLabel folder_label;
    private Mail.Models.IFolder _folder;

    public Mail.Models.IFolder folder { get { return _folder; } }

    public FolderItem (Mail.Models.IFolder folder) {
        _folder = folder;

        build_ui ();
    }

    private void build_ui () {
        margin_top = 4;
        margin_bottom = 4;
        margin_left = 8;
        margin_right = 8;

        add (new Mail.FolderLabel(folder));

        show_all ();
    }
}

