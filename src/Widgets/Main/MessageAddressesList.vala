/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
