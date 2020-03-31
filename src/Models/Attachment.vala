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

public class Envoyer.Models.Attachment : GLib.Object {
    
    public string file_name { get; construct set; }
    public string mime_type { get;  construct set; }
    public string character_set { get; construct set; }
    public string content_id { get; construct set; }
    public string content_location { get; construct set; }
    public string part_id { get; construct set; }
    public int64 encoding { get; construct set; }
    public bool is_inline { get; construct set; }

    public Bytes? data { get; set; }    //@TODO this doesn't need to be Bytes, it can just be a simple Vala buffer

    public string content_type {
        owned get {
            var result_uncertain = false;

            var content_type = ContentType.guess (file_name, data.get_data (), out result_uncertain);

            if (result_uncertain) {
                content_type = ContentType.from_mime_type (mime_type);
            }

            return content_type;
        }
    }
 
    public Attachment (
            string file_name,
            string mime_type,
            string character_set,
            string content_id,
            string content_location,
            string part_id,
            int64 encoding,
            bool is_inline
        ) {

        Object (
            file_name: file_name.dup (),
            mime_type: mime_type.dup ().down (),
            character_set: character_set.dup (),
            content_id: content_id.dup (),
            content_location: content_location.dup (),
            part_id: part_id.dup (),
            encoding: encoding,
            is_inline: is_inline
        );
    }

    public Attachment.with_data (
            string file_name,
            string mime_type,
            string character_set,
            string content_id,
            string content_location,
            string part_id,
            int64 encoding,
            bool is_inline,
            GLib.Bytes data
        ) {

        Object (
            file_name: file_name.dup (),
            mime_type: mime_type.dup ().down (),
            character_set: character_set.dup (),
            content_id: content_id.dup (),
            content_location: content_location.dup (),
            part_id: part_id.dup (),
            encoding: encoding,
            is_inline: is_inline,
            data: data
        );
    }
}
