public class Mail.FolderItem : Gtk.ListBoxRow {
    public Mail.Models.Folder folder { get { return _folder; } }

    private Gtk.Grid grid;
    private Gtk.Label title;
    private Gtk.Image icon;
    private Gtk.Label unread_count;
    private Mail.Models.Folder _folder;
    private string label_override;

    public FolderItem (Mail.Models.Folder folder, string label = "") { //@TODO move the label in Folder.vala
        _folder = folder;
        label_override = label;
        
        build_ui ();
    }

    private void build_ui () {
        set_activatable (true);

        grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("h3");
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_left = 8;
        grid.margin_right = 8; //@TODO this should be done in CSS
        
        icon = new Gtk.Image.from_icon_name (get_icon_name (), Gtk.IconSize.BUTTON);
        icon.margin_right = 3;

        title = new Gtk.Label ("");
        title.use_markup = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title).xalign = 0;	    

        unread_count = new Gtk.Label ("");
        unread_count.halign = Gtk.Align.START;
	    unread_count.ellipsize = Pango.EllipsizeMode.END;
        unread_count.margin_left = 8;
        ((Gtk.Misc) unread_count).xalign = 0;
        unread_count.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        this.add (grid);
        grid.add (icon);
        grid.add (title);
        grid.add (unread_count);

        load_data ();
        this.show_all ();
    }

    private void load_data () {
        this.unread_count.label = "%u".printf(folder.unread_count);
        this.title.label = "%s".printf(label_override == "" ? folder.display_name : label_override); //@TODO move this to Folder.vala
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

