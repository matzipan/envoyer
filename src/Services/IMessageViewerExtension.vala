/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

[DBus (name = "@PROJECT_FQDN@.MessageViewerExtension")]
public interface Envoyer.Services.IMessageViewerExtension : GLib.Object {
    public abstract uint get_height () throws GLib.IOError;
}
