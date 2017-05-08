/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Services.Session : GLib.Object {
    public async Session () {
        Object();
    
        void* session = MailCoreInterface.connect (settings.username, settings.password);
        
        MailCoreInterface.fetch (session);
    }
}
