/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.Address : GLib.Object {
    public string name { get; construct set; }
    public string email { get; construct set; }
    
    public Address (string name, string email) {
        Object(name: name.dup (), email: email.dup ());
    }
    
    public string to_string () {
        if (name == "") {
            return email;
        } else {
            return "%s <%s>".printf (name, email);
        }
    }
}
