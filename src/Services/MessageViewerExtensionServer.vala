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
