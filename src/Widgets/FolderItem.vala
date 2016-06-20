public class Mail.FolderItem : Gtk.ListBoxRow {
    private Gtk.Grid grid;
    private Mail.FolderLabel folder_label;
    public Mail.Models.IFolder folder { get; private set; }

    public FolderItem (Mail.Models.IFolder folder) {
        this.folder = folder;

        build_ui ();
    }

    private void build_ui () {
        grid = new Gtk.Grid ();
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_right = 8;

        set_margin_left (20);

        grid.add (new Mail.FolderLabel(folder));

        add (grid);

        show_all ();
    }
    
    protected void set_margin_left (int margin) {
        grid.margin_left = margin;
    }
}

