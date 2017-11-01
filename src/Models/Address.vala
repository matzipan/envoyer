/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Models.Address : GLib.Object {
    public string name { get; construct set; }
    public string email { get; construct set; }

    public string display_name { get {
            if (name == "") {
                return email;
            } else {
                return name;
            }
        }
    }

    public Address (string name, string email) {
        Object(name: name.dup (), email: email.dup ());
    }

    public Address.from_string (string address) {
        var pattern = new Regex("(?:\"?([^\"]*)\"?\\s)?(?:<?(.+@[^>]+)>?)");

        MatchInfo match_info;
        var matched_name = "";
        var matched_email = "";
        if (pattern.match(address, 0, out match_info)) {
            matched_name = match_info.fetch(0);
            matched_email = match_info.fetch(1);
        }

        // Have to store the matches in temporary variables since Vala doesn't like 2 calls to the constructor.
        Object(name: matched_name, email: matched_email);
    }

    public string to_string () {
        if (name == "") {
            return email;
        } else {
            return "%s <%s>".printf (name, email);
        }
    }
}
