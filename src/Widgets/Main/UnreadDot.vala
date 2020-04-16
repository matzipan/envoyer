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
    private const int margin_top = 1;

    private string class_string = "unread_dot";

    private Gtk.StyleContext style_context {
        owned get {
            var style_path = get_path ();
            style_path.append_type (typeof (Gtk.Widget));
        
            var widget_style_context = new Gtk.StyleContext ();
            widget_style_context.set_path (style_path);
            widget_style_context.add_class (class_string);

            return widget_style_context;
        }
    }

    construct {
        set_size_request (width, height);
    }

    public override bool draw (Cairo.Context cr) {
        Gdk.cairo_set_source_rgba (cr, style_context.get_color (Gtk.StateFlags.NORMAL));

        var center_x = (width - dot_radius * 2) / 2 + dot_radius;
        var center_y = (height - dot_radius * 2) / 2 + dot_radius + margin_top;

        cr.arc (center_x, center_y, dot_radius, 0, 2 * GLib.Math.PI);
        cr.fill ();
        
        return true;      
    }
}