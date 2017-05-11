/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Services.Session : GLib.Object {
    //@TODO rename class to Identity
    public void* session { get; private set; }
    public string name { get; construct set; }
    
    public async Session (string username, string password, string name) {
        Object(name: name);
    
        session = MailCoreInterface.connect (username, password);        
    }
}
