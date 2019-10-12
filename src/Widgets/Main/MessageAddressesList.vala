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

public class Envoyer.Widgets.Main.MessageAddressesList : Egg.WrapBox {

    public MessageAddressesList () {
        Object ();
    }

    construct {
        build_ui ();
    }

    private void build_ui () {
        allocation_mode = Egg.WrapAllocationMode.FREE;
        horizontal_spreading = Egg.WrapBoxSpreading.START;
        vertical_spreading = Egg.WrapBoxSpreading.START;
        horizontal_spacing = 4;
        vertical_spacing = 4;
    }

    public void load_data (Gee.Collection<Envoyer.Models.Address> addresses) {
        var addresses_length = addresses.size;
        var i = 0;

        foreach(var address in addresses) {
            var label = new Gtk.Label(null);
            label.tooltip_text = address.to_string();

            var addresses_string_builder = new GLib.StringBuilder ();
            addresses_string_builder.append (address.display_name);
            if (i != (addresses_length - 1)) {
                addresses_string_builder.append (",");
            }
            label.set_label(addresses_string_builder.str);

            add(label);

            i++;
        }
    }
}
