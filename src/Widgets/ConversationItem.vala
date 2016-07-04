/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Widgets.ConversationItem : Gtk.ListBoxRow {
    private Gtk.Grid grid;
    private Gtk.Label subject;
    public Envoyer.Models.ConversationThread thread { get; private set; }

    public ConversationItem (Envoyer.Models.ConversationThread thread) {
        this.thread = thread;
        build_ui ();
    }

    private void build_ui () {
        grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("h3");
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.margin_top = 4;
        grid.margin_bottom = 4;
        grid.margin_left = 8;
        grid.margin_right = 8;

        subject = new Gtk.Label ("");
        subject.use_markup = true;
        subject.halign = Gtk.Align.START;
        subject.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) subject).xalign = 0;	    

        this.add (grid);
        grid.add (subject);

        load_data ();
        this.show_all ();
    }

    private void load_data () {
        this.subject.label = "<b>%s</b>".printf(thread.subject);
    }
}

