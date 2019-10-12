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

public class Envoyer.Widgets.Main.MessageViewer : Gtk.ListBoxRow {
    private MessageWebView message_webview;
    private Gtk.Grid grid;
    private Gtk.Grid message_header;
    private Gtk.Grid header_summary_fields;
    private Gtk.Button attachment_image;
    private Gtk.Label datetime_received_label;
    private Gtk.Label subject_label;
    private Gtk.Label from_address_label;
    private Envoyer.Widgets.Main.MessageAddressesList to_addresses_list;
    private Gtk.Grid to_addresses_grid;
    private Gtk.Label to_addresses_label;
    private Envoyer.Widgets.Main.MessageAddressesList cc_addresses_list;
    private Gtk.Grid cc_addresses_grid;
    private Gtk.Label cc_addresses_label;
    private Envoyer.Widgets.Main.MessageAddressesList bcc_addresses_list;
    private Gtk.Grid bcc_addresses_grid;
    private Gtk.Label bcc_addresses_label;
    private Envoyer.Widgets.Gravatar avatar;

    private Message message_item;

    public signal void link_mouse_in (string uri);
    public signal void link_mouse_out ();

    public MessageViewer (Message message_item) {
        this.message_item = message_item;

        build_ui ();
        connect_signals ();
        load_data ();
    }

    private void build_ui () {
        //@TODO print button for message/thread

        expand = true;
        selectable = false;

        avatar = new Envoyer.Widgets.Gravatar.with_default_icon (48);
        avatar.valign = Gtk.Align.START;

        subject_label = build_label ();
        subject_label.get_style_context ().add_class ("subject");
        subject_label.xalign = 0;
        from_address_label = build_label ();
        from_address_label.get_style_context ().add_class ("from");
        from_address_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        build_addresses_field ("to", "to", out to_addresses_label, out to_addresses_list, out to_addresses_grid);
        build_addresses_field ("cc", "cc", out cc_addresses_label, out cc_addresses_list, out cc_addresses_grid);
        build_addresses_field ("bcc", "bcc", out bcc_addresses_label, out bcc_addresses_list, out bcc_addresses_grid);

        header_summary_fields = new Gtk.Grid ();
        header_summary_fields.row_spacing = 1;
        header_summary_fields.margin_top = 6;
        header_summary_fields.margin_bottom = 6;
        header_summary_fields.hexpand = true;
        header_summary_fields.valign = Gtk.Align.START;
        header_summary_fields.orientation = Gtk.Orientation.VERTICAL;
        header_summary_fields.add (subject_label);
        header_summary_fields.add (from_address_label);
        header_summary_fields.add (to_addresses_grid);
        header_summary_fields.add (cc_addresses_grid);
        header_summary_fields.add (bcc_addresses_grid);

        datetime_received_label = new Gtk.Label (null);
        datetime_received_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        datetime_received_label.valign = Gtk.Align.START;
        datetime_received_label.margin_top = 6;
        datetime_received_label.margin_right = 10;

        attachment_image = new Gtk.Button.from_icon_name ("mail-attachment-symbolic", Gtk.IconSize.MENU);
        attachment_image.get_style_context ().remove_class ("button");
        attachment_image.margin_top = 6;
        attachment_image.valign = Gtk.Align.START;
        attachment_image.sensitive = false;
        attachment_image.tooltip_text = _("This message contains one or more attachments");

        message_header = new Gtk.Grid ();
        message_header.can_focus = false;
        message_header.orientation = Gtk.Orientation.HORIZONTAL;
        message_header.margin = 3;
        message_header.column_spacing = 2;
        message_header.add (avatar);
        message_header.add (header_summary_fields);
        message_header.add (attachment_image);
        message_header.add (datetime_received_label);

        message_webview = new MessageWebView ();

        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.column_spacing = 3;
        grid.add (message_header);
        grid.add (message_webview);

        add (grid);
        show_all ();
    }

    private void build_addresses_field (string style_class_name, string label_text, out Gtk.Label addresses_label, out Envoyer.Widgets.Main.MessageAddressesList addresses_list, out Gtk.Grid addresses_grid) {
        addresses_label = new Gtk.Label(label_text);
        addresses_label.valign = Gtk.Align.START;

        addresses_list = new Envoyer.Widgets.Main.MessageAddressesList();
        addresses_list.margin_left = 3;
        addresses_list.expand = true;

        addresses_grid = new Gtk.Grid ();
        addresses_grid.get_style_context ().add_class (style_class_name);
        addresses_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        addresses_grid.add(addresses_label);
        addresses_grid.add(addresses_list);
    }

    private void connect_signals () {
        message_webview.scroll_event.connect (propagate_scroll_event);
        message_webview.link_mouse_in.connect ((uri) => { link_mouse_in (uri); });
        message_webview.link_mouse_out.connect (() => { link_mouse_out (); });
    }

    private bool propagate_scroll_event (Gdk.EventScroll event) {
        /*
         * This propagates the event from the WebView upwards toward ConversationViewer. I admit
         * that this solution feels hacky, but I could not find any other working solution for
         * propagating the scroll event upwards.
         */
        scroll_event (event);

        return Gdk.EVENT_PROPAGATE;
    }

    private Gtk.Label build_label () {
        var address_label = new Gtk.Label (null);
        address_label.ellipsize = Pango.EllipsizeMode.END;
        address_label.halign = Gtk.Align.START;

        return address_label;
    }

    private void load_data () {
        message_webview.load_html (message_item.content, null);

        if (message_item.subject == "") {
            subject_label.destroy ();
        } else {
            subject_label.set_label (message_item.subject);
        }
        from_address_label.set_label (message_item.from.display_name);
        from_address_label.tooltip_text = message_item.from.to_string ();

        if(message_item.to.size == 0) {
            to_addresses_grid.visible = false;
            to_addresses_grid.no_show_all = true;
        } else {
            to_addresses_list.load_data(message_item.to);
        }

        if(message_item.cc.size == 0) {
            cc_addresses_grid.visible = false;
            cc_addresses_grid.no_show_all = true;
        } else {
            cc_addresses_list.load_data(message_item.cc);
        }

        if(message_item.bcc.size == 0) {

            bcc_addresses_grid.visible = false;
            bcc_addresses_grid.no_show_all = true;
        } else {
            bcc_addresses_list.load_data(message_item.bcc);
        }

        if(!message_item.has_attachment) {
            attachment_image.destroy ();
        }

        avatar.set_address (message_item.from);
        avatar.fetch_async ();

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

        datetime_received_label.tooltip_text = message_item.datetime_received.format(full_format);

        var humanDateTime = new Envoyer.FutureGranite.HumanDateTime(message_item.datetime_received);
        datetime_received_label.set_label (humanDateTime.compared_to_now ());
    }

    private string build_addresses_string (Gee.Collection<Envoyer.Models.Address> addresses) {
            // @TODO replace indentity email address with "me"
            var addresses_string_builder = new GLib.StringBuilder ();
            var first = true;

            foreach (var address in addresses) {
                if (first) {
                    first = false;
                    addresses_string_builder.append (address.display_name);
                } else {
                    addresses_string_builder.append (", ");
                    addresses_string_builder.append (address.display_name);
                }
            }

            return addresses_string_builder.str;
    }
}
