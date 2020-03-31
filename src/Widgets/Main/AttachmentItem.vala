/*
 * Copyright (C) 2020  Andrei-Costin Zisu
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

using Envoyer.Globals.Application;
using Envoyer.Models;

public class Envoyer.Widgets.AttachmentItem : Gtk.EventBox {
    private Gtk.Image icon_image;
    private Gtk.Label name_label;
    private Gtk.Grid grid;

    private Attachment model;
 
    public AttachmentItem (Attachment attachment) {
        this.model = attachment;

        build_ui ();
        connect_signals ();
        load_data ();
    }
 
    private void build_ui () {
        icon_image = new Gtk.Image ();
        name_label = new Gtk.Label ("");

        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        add (grid);

        grid.add (icon_image);
        grid.add (name_label);
    }
 
    private void load_data () {
        var icon = ContentType.get_icon (model.content_type);

        icon_image.set_from_gicon (icon, Gtk.IconSize.DND);
        name_label.set_text (model.file_name);
    }

    private void connect_signals () {
        set_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        button_press_event.connect ((event) => {
        //@TODO Dialog for confirmation about opening, inspiration here: https://github.com/elementary/mail/blob/8a9d661ad79504dd44971ef00d16b8efc86b0cf7/src/Dialogs/OpenAttachmentDialog.vala

            if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
                show_attachment.begin (model);
            }

            return Gdk.EVENT_PROPAGATE;
        });
    }

    //@TODO the controller or the application should be the one actually opening the file, not the message viewer
    private async void show_attachment (Envoyer.Models.Attachment attachment) {
        try {
            GLib.FileIOStream iostream;
            var file = File.new_tmp ("XXXXXX-%s".printf (attachment.file_name), out iostream);
            if (file == null) {
                //@TODO raise exception
            }

            var output_stream = iostream.get_output_stream ();
            size_t bytes_written;
            yield output_stream.write_all_async (attachment.data.get_data (), GLib.Priority.HIGH, null, out bytes_written);
            yield GLib.AppInfo.launch_default_for_uri_async (file.get_uri (), (AppLaunchContext) null, null);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
 