/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.Address : GLib.Object {
    public string name { get; private set; }
    public string email { get; private set; }
    
    public Address (string name, string email) {
        this.name = name;
        this.email = email;
    }
    
    public string to_string () {
        if (name == "") {
            return email;
        } else {
            return "%s <%s>".printf(name, email);
        }
    }
}
