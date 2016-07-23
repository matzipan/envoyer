public class Envoyer.Widgets.MessageViewer : Gtk.ListBoxRow {
    private Envoyer.Widgets.MessageWebView message_webview;
    private Gtk.Grid grid;
    private Gtk.Grid message_header;
    private Gtk.Grid header_summary_fields;
    private Gtk.Button attachment_image;
    private Gtk.Label datetime_label;
    private Gtk.Label from_address_label;
    private Gtk.Label to_address_label;
    private Gtk.Label cc_address_label;
    private Gtk.Label bcc_address_label;
    private Envoyer.Widgets.Gravatar avatar;
    
    private Envoyer.Models.Message message_item;

    public MessageViewer (Envoyer.Models.Message message_item) {
        this.message_item = message_item;

        build_ui ();
        connect_signals ();
        load_data ();
    }

    private void build_ui () {
        expand = true;
        selectable = false;

        avatar = new Envoyer.Widgets.Gravatar.with_default_icon (48);
        avatar.valign = Gtk.Align.START;

        from_address_label = build_address_label ();
        to_address_label = build_address_label ();
        cc_address_label = build_address_label ();
        bcc_address_label = build_address_label ();
        
        header_summary_fields = new Gtk.Grid ();
        header_summary_fields.row_spacing = 1;
        header_summary_fields.margin_top = 6;
        header_summary_fields.margin_bottom = 6;
        header_summary_fields.orientation = Gtk.Orientation.VERTICAL;
        header_summary_fields.add (from_address_label);
        header_summary_fields.add (to_address_label);
        header_summary_fields.add (cc_address_label);
        header_summary_fields.add (bcc_address_label);

        datetime_label = new Gtk.Label (null);
        datetime_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        datetime_label.margin_top = 6;
        datetime_label.margin_right = 10;
        datetime_label.halign = Gtk.Align.END;
        datetime_label.valign = Gtk.Align.START;

        attachment_image = new Gtk.Button.from_icon_name ("mail-attachment-symbolic", Gtk.IconSize.MENU);
        attachment_image.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        attachment_image.margin_top = 6;
        attachment_image.valign = Gtk.Align.START;
        attachment_image.halign = Gtk.Align.END;
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
        message_header.add (datetime_label);

        message_webview = new Envoyer.Widgets.MessageWebView ();
        
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (message_header);
        grid.add (message_webview);

        add (grid);
        show_all ();
    }
    
    private void connect_signals () {
        message_webview.scroll_event.connect (propagate_scroll_event);
    }
    
    private bool propagate_scroll_event (Gdk.EventScroll event) {
        /*
         * This propagates the event from the WebView upwards toward ConversationViewer. I admit 
         * that this solution feels hacky, but I could not find any other working solution for 
         * propagating the scroll event upwards. 
         */
        scroll_event (event);
        
        return Gdk.EVENT_STOP;
    }
    
    private Gtk.Label build_address_label () {
        var address_label = new Gtk.Label (null);
        address_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) address_label).xalign = 0;
        address_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        address_label.hexpand = true;
        address_label.use_markup = true;
        address_label.valign = Gtk.Align.BASELINE;
        
        return address_label;
    }

    private void load_data () {
        message_webview.load_html (message_item.content, null);
        from_address_label.set_label (message_item.from.to_escaped_string ());
        to_address_label.set_label (build_addresses_string (message_item.to));
        
        var addresses = build_addresses_string (message_item.cc);
        if (addresses == "") {
            cc_address_label.destroy ();
        } else {
            cc_address_label.set_label (addresses);
        }
        
        addresses = build_addresses_string (message_item.bcc);
        if (addresses == "") {
            bcc_address_label.destroy ();
        } else {
            bcc_address_label.set_label (addresses);
        }
        
        if(!message_item.has_attachment) {
            attachment_image.destroy ();
        }
        
        avatar.set_address (message_item.from);
        avatar.fetch_async ();
        
        setup_timestamp ();
    }
    
    private void setup_timestamp () {  
        update_timestamp ();
        
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
                                    
        datetime_label.tooltip_text = message_item.datetime.format(full_format);
    
        var humanDateTime = new Envoyer.FutureGranite.HumanDateTime(message_item.datetime);
        datetime_label.set_label (humanDateTime.compared_to_now ());
    }
    
    private string build_addresses_string (Gee.Collection<Envoyer.Models.Address> addresses) {
            // @TODO replace indentity email address with "me" 
            var addresses_string_builder = new GLib.StringBuilder ();
            var first = true;

            foreach (var address in addresses) {
                if (first) {
                    first = false;
                    addresses_string_builder.append (address.to_escaped_string ());
                } else {
                    addresses_string_builder.append (", %s".printf(address.to_escaped_string ()));
                }
            }
            
            return addresses_string_builder.str;
    }
}
