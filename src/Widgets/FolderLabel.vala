public class Mail.FolderLabel : Gtk.Grid {
    private Gtk.Label name_label;
    private Gtk.Label unread_count_label;
    private Mail.Models.IFolder folder;

    public FolderLabel (Mail.Models.IFolder folder) {
        this.folder = folder;

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        name_label = new Gtk.Label ("");
        name_label.get_style_context ().add_class ("h3");
        name_label.halign = Gtk.Align.START;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) name_label).xalign = 0;

        unread_count_label = new Gtk.Label ("");
        unread_count_label.halign = Gtk.Align.START;
	    unread_count_label.ellipsize = Pango.EllipsizeMode.END;
        unread_count_label.margin_left = 8;
        ((Gtk.Misc) unread_count_label).xalign = 0;
        unread_count_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        add (name_label);
        add (unread_count_label);

        load_data ();
        show_all ();
    }
    
    private void load_data () {
        set_unread_count (folder.unread_count);
        set_name (folder.display_name);
    }

    private void connect_signals () {
        folder.unread_count_changed.connect (set_unread_count);
        folder.display_name_changed.connect (set_name);
    }
    
    private void set_unread_count (uint unread_count) {
        unread_count_label.label = "%u".printf(unread_count);
    }
    
    private void set_name (string name) {
        name_label.label = "%s".printf(name);
    }
}