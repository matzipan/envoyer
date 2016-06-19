public class Mail.FolderItem : Gtk.ListBoxRow {
    private Gtk.Box box;
    private Mail.FolderLabel folder_label;
    private Mail.Models.IFolder _folder;

    public Mail.Models.IFolder folder { get { return _folder; } }

    public FolderItem (Mail.Models.IFolder folder) {
        _folder = folder;

        build_ui ();
    }

    private void build_ui () {
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_top = 4;
        box.margin_bottom = 4;
        box.margin_right = 8;

        set_margin_left (20);

        box.add (new Mail.FolderLabel(folder));

        add (box);

        show_all ();
    }
    
    protected void set_margin_left (int margin) {
        box.margin_left = margin;
    }
}

