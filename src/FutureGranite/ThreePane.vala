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

public class Envoyer.FutureGranite.ThreePane : Gtk.Grid {

    public Gtk.Widget child_left { get; private set; default = null; }
    public Gtk.Widget child_center { get; private set; default = null; }
    public Gtk.Widget child_right { get; private set; default = null; }


    public ThreePane () {
        build_ui ();
    }

    public ThreePane.with_children (Gtk.Widget left, Gtk.Widget center, Gtk.Widget right) {
        child_left = left;
        child_center = center;
        child_right = right;

        build_ui ();
    }

    public void build_ui () {
        add (child_left);
        //@TODO add resize handles
        add (child_center);
        //@TODO add resize handles
        add (child_right);
    }

    //@TODO add left, add_center add_right
    //@TODO remove left, remove center, remvoe right

}
