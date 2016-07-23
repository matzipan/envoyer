/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Widgets.FolderLabel : Gtk.Grid {
    private Gtk.Label name_label;
    private Gtk.Label unread_count_label;
    private Gtk.Image icon;
    private Envoyer.Models.IFolder folder;

    public FolderLabel (Envoyer.Models.IFolder folder) {
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
        
        icon = new Gtk.Image.from_icon_name (get_icon_name (), Gtk.IconSize.BUTTON);
        icon.margin_right = 3;
        
        add (icon);
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
    
    public string get_icon_name () {
        if(folder.is_inbox) {
            return "mail-inbox";
        } else if(folder.is_trash) {
            //@TODO listen to total_count_changed signal and change the icon accordingly
            if(folder.total_count == 0) {
                return "user-trash";
            } else {
                return "user-trash-full";
            }
        } else if(folder.is_outbox) {
            return "mail-outbox";
        } else if(folder.is_sent) {
            return "mail-sent";
        } else if(folder.is_spam) {
            return "edit-flag";
        } else if(folder.is_starred) {
            return "starred";
        } else if(folder.is_drafts) {
            return "folder-documents";    
        } else if(folder.is_all_mail || folder.is_archive) {
            return "mail-archive";
        } else {
            return "folder-tag";
        }        
    }
}