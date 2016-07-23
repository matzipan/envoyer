/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
