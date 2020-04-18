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

public class Envoyer.Widgets.Main.UnreadDot : Gtk.DrawingArea {
    private const int dot_radius = 4;
    private const int width = 10;
    private const int height = 16;

    construct {
        set_size_request (width, height);
        get_style_context ().add_class ("unread_dot");
    }

    public override bool draw (Cairo.Context cr) {
        Gdk.cairo_set_source_rgba (cr, get_style_context ().get_color (get_state_flags ()));

        var center_x = (width - dot_radius * 2) / 2 + dot_radius;
        var center_y = (height - dot_radius * 2) / 2 + dot_radius + margin_top;

        cr.arc (center_x, center_y, dot_radius, 0, 2 * GLib.Math.PI);
        cr.fill ();
        
        return true;      
    }
}