/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Widgets.FolderConversationItem : Gtk.ListBoxRow {
    private Gtk.Grid top_grid;
    private Gtk.Grid bottom_grid;
    private Gtk.Grid outer_grid;
    private Gtk.Label subject_label;
    private Gtk.Label addresses_label;
    private Gtk.Button attachment_image;
    private Gtk.Button star_image;
    private Gtk.Label datetime_received_label;
    private double current_size = 0;
    public Envoyer.Models.ConversationThread thread { get; private set; }

    public FolderConversationItem (Envoyer.Models.ConversationThread thread) {
        this.thread = thread;
        build_ui ();
    }

    private void build_ui () {
        subject_label = new Gtk.Label ("");
        subject_label.hexpand = true;
        subject_label.halign = Gtk.Align.START;
        subject_label.ellipsize = Pango.EllipsizeMode.END;
        subject_label.get_style_context ().add_class ("subject");

        attachment_image = new Gtk.Button.from_icon_name ("mail-attachment-symbolic", Gtk.IconSize.MENU);
        attachment_image.get_style_context ().remove_class ("button");
        attachment_image.sensitive = false;
        attachment_image.tooltip_text = _("This thread contains one or more attachments");

        top_grid = new Gtk.Grid ();
        top_grid.orientation = Gtk.Orientation.HORIZONTAL;
        top_grid.column_spacing = 3;
        top_grid.add (subject_label);
        top_grid.add (attachment_image);
        
        star_image = new Gtk.Button.from_icon_name ("starred", Gtk.IconSize.MENU); //@TODO make smaller
        star_image.get_style_context ().remove_class ("button");
        star_image.sensitive = true;
        star_image.tooltip_text = _("Mark this thread as starred");

        addresses_label = new Gtk.Label ("");
        addresses_label.hexpand = true;
        addresses_label.halign = Gtk.Align.START;
        addresses_label.ellipsize = Pango.EllipsizeMode.END;
        addresses_label.get_style_context ().add_class ("addresses");
        addresses_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        
        datetime_received_label = new Gtk.Label (null);

        bottom_grid = new Gtk.Grid ();
        bottom_grid.orientation = Gtk.Orientation.HORIZONTAL;
        bottom_grid.column_spacing = 3;
        bottom_grid.add (addresses_label);
        bottom_grid.add (star_image);
        bottom_grid.add (datetime_received_label);

        outer_grid = new Gtk.Grid ();
        outer_grid.orientation = Gtk.Orientation.VERTICAL;
        outer_grid.row_spacing = 3;
        outer_grid.margin_top = 4;
        outer_grid.margin_bottom = 4;
        outer_grid.margin_left = 8;
        outer_grid.margin_right = 8;
        outer_grid.add (top_grid);
        outer_grid.add (bottom_grid);

        add (outer_grid);
        load_data ();
        show_all ();
    }

    private void load_data () {
        subject_label.label = thread.subject;
        subject_label.tooltip_text = thread.subject;
        datetime_received_label.label = thread.subject;
        addresses_label.label = "me, Tom Cone, Mike"; //@TODO
        /*if (true) {
            //subject_label.get_style_context ().add_class ("unread");
        }*/

        attachment_image.destroy (); //@TODO
        star_image.destroy (); //@TODO

        setup_timestamp ();
    }
    
    private void setup_timestamp () {  
        update_timestamp (); //@TODO mabe write an autoupdating timestamp class

        var timeout_reference = GLib.Timeout.add_seconds(10, () => { 
            update_timestamp();
            
            return true; 
        });
        
        unrealize.connect(() => { 
            GLib.Source.remove (timeout_reference);
        });
    }
    
    private void update_timestamp () {
        var full_format = "%s %s".printf(
                                    Granite.DateTime.get_default_date_format(false, true, true),
                                    Granite.DateTime.get_default_time_format(false, true)
                                    );
                                    
        datetime_received_label.tooltip_text = thread.datetime_received.format(full_format);
    
        var humanDateTime = new Envoyer.FutureGranite.HumanDateTime(thread.datetime_received);
        datetime_received_label.set_label (humanDateTime.compared_to_now ());
    }
}

