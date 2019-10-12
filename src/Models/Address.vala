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
            matched_name = match_info.fetch(1);
            matched_email = match_info.fetch(2);
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
