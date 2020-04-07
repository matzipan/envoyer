/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

using Envoyer.Models;

public class Envoyer.Widgets.Main.FolderConversationItem : SwipeActionListBoxRow {
    private Gtk.Grid top_grid;
    private Gtk.Grid bottom_grid;
    private Gtk.Grid outer_grid;
    private Gtk.Label subject_label;
    private Gtk.Label addresses_label;
    private Gtk.Image attachment_image;
    private Gtk.Button star_image;
    private Gtk.Label datetime_received_label;
    private double current_size = 0;
    public ConversationThread thread { get; private set; }

    public FolderConversationItem (ConversationThread thread) {
        this.thread = thread;
        build_ui ();
        connect_signals ();
        load_data ();
        show_all ();
    }

    private void build_ui () {
        subject_label = new Gtk.Label ("");
        subject_label.hexpand = true;
        subject_label.halign = Gtk.Align.START;
        subject_label.ellipsize = Pango.EllipsizeMode.END;
        subject_label.get_style_context ().add_class ("subject");
        subject_label.xalign = 0;

        attachment_image = new Gtk.Image.from_icon_name ("mail-attachment-symbolic", Gtk.IconSize.MENU);
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
        bottom_grid.add (datetime_received_label);
        bottom_grid.add (star_image);

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

        set_swipe_icon_name ("envoyer-delete-symbolic");
    }

    private void load_data () {
        subject_label.label = thread.subject;
        subject_label.tooltip_text = thread.subject;
        var full_format = "%s %s".printf(
                                    Granite.DateTime.get_default_date_format(false, true, true),
                                    Granite.DateTime.get_default_time_format(false, true)
                                    );

        datetime_received_label.tooltip_text = thread.datetime_received.format(full_format);

        addresses_label.label = build_addresses_string (thread.display_addresses);
        if (!thread.seen) {
            subject_label.get_style_context ().add_class ("unread"); //@TODO if flag is updated
        }

        if (!thread.has_non_inline_attachments) {
            attachment_image.destroy ();
        }

        if (!thread.flagged) {
            star_image.destroy (); //@TODO if flag is updated
        }

        setup_timestamp ();
    }

    private void connect_signals () {
        action_triggered.connect (() => {
        //@TODO bubble up signal for action at folderconversationitem level, also the hide should be there
        hide ();
        });
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
        var humanDateTime = new Envoyer.FutureGranite.HumanDateTime(thread.datetime_received);
        datetime_received_label.set_label (humanDateTime.compared_to_now ());
    }

    private string build_addresses_string (Gee.Collection<Envoyer.Models.Address> addresses) {
            var addresses_string_builder = new GLib.StringBuilder ();
            var first = true;

            //@TODO if there is more than one address, just use the first word
            foreach (var address in addresses) {
                var address_display_name = address.display_name;
                
                foreach (var identity in Envoyer.Globals.Application.identities) {
                    if(identity.address.email == address.email) {
                      address_display_name = _("me");
                      break;
                    }
                }
                                
                if (first) {
                    first = false;
                    addresses_string_builder.append (address_display_name);
                } else {
                    addresses_string_builder.append (", ");
                    addresses_string_builder.append (address_display_name);
                }
            }

            return addresses_string_builder.str;
    }
}
