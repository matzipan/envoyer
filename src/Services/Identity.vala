/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Services.Identity : GLib.Object {
    public void* session { get; construct set; }
    public string name { get; construct set; }
    
    public async Identity (string username, string password, string name) {
        Object(name: name, session: MailCoreInterface.connect (username, password));
    }
}
