public class Mail.FolderItem : Gtk.ListBoxRow {
    private Gtk.Grid grid;
    private Gtk.Label name_label;
    private Gtk.Image icon;
    private Gtk.Label unread_count_label;
    private Mail.Models.IFolder _folder;

    public Mail.Models.IFolder folder { get { return _folder; } }

    public FolderItem (Mail.Models.IFolder folder) {
        _folder = folder;

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        set_activatable (true);

        grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("h3");
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_left = 8;
        grid.margin_right = 8;
        
        icon = new Gtk.Image.from_icon_name (get_icon_name (), Gtk.IconSize.BUTTON);
        icon.margin_right = 3;

        name_label = new Gtk.Label ("");
        name_label.use_markup = true;
        name_label.halign = Gtk.Align.START;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) name_label).xalign = 0;

        unread_count_label = new Gtk.Label ("");
        unread_count_label.halign = Gtk.Align.START;
	    unread_count_label.ellipsize = Pango.EllipsizeMode.END;
        unread_count_label.margin_left = 8;
        ((Gtk.Misc) unread_count_label).xalign = 0;
        unread_count_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        this.add (grid);
        grid.add (icon);
        grid.add (name_label);
        grid.add (unread_count_label);

        load_data ();
        this.show_all ();
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
    
    public string get_icon_name () {

        
        if(folder.is_inbox) {
            return "mail-inbox";
        } else if(folder.is_trash) {
            //return folder.properties.email_total == 0 ? "user-trash" : "user-trash-full"; @TODO
            return "user-trash";
        } else if(folder.is_outbox) {
            return "mail-outbox";
        } else if(folder.is_sent) {
            return "mail-sent";
        } else if(folder.is_junk) {
            return "edit-flag";
        } else if(folder.is_starred) {
            return "starred";
        } else {
            return "folder-tag";
        }

    
        /*
            case Geary.SpecialFolderType.DRAFTS:
                return "folder-documents";
            case Geary.SpecialFolderType.IMPORTANT:
                return "mail-mark-important";

            case Geary.SpecialFolderType.ALL_MAIL:
            case Geary.SpecialFolderType.ARCHIVE:
                return "mail-archive";*/
        
    }
}

