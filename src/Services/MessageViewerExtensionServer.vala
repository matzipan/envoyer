/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
[DBus (name = "@PROJECT_FQDN@.MessageViewerExtension")]
public class Envoyer.Services.MessageViewerExtensionServer : GLib.Object, Envoyer.Services.IMessageViewerExtension {
    private WebKit.WebPage page;
    private uint web_view_id;

    [DBus (visible = false)]
    public MessageViewerExtensionServer (uint web_view_id) {
        this.web_view_id = web_view_id;
        
        GLib.Bus.own_name(
            GLib.BusType.SESSION,
            "%s.MessageViewerExtension.id%u".printf(Constants.PROJECT_FQDN, web_view_id),
            GLib.BusNameOwnerFlags.NONE,
            on_bus_aquired,
            null,
            on_unable_acquire_name
        );
    }

    [DBus (visible = false)]
    public void on_bus_aquired(DBusConnection connection) {
        try {
            connection.register_object("%s/MesssageViewerExtension".printf(Constants.DBUS_OBJECTS), this);
        } catch (IOError error) {
            warning("Could not register service: %s", error.message);
        }
    }
    
    [DBus (visible = false)]
    public void on_unable_acquire_name(DBusConnection connection) {
        warning("Could not aquire name");
    }
    
    [DBus (visible = false)]
    public void on_page_created(WebKit.WebExtension extension, WebKit.WebPage page) {
        this.page = page;
    }

    public uint get_height () {
        return (uint) page.get_dom_document ().body.scroll_height;
    }
}
