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

public class Envoyer.Models.Message : GLib.Object {
    public Folder folder;

    //@TODO find a way to either integrate this or get rid of it. needed for html fetching
    public void* mailcore_message { get; construct set; }
    public Address from { get; set; }
    public Address sender { get; set; }
    public uint uid { get; construct set; }
    public bool seen { get; construct set; }
    public bool flagged { get; construct set; }
    public bool deleted { get; construct set; }
    public bool draft { get; construct set; }
    public uint modification_sequence { get; construct set; }
    public Gee.Collection<Address> to { get; set; }
    public Gee.Collection<Address> cc { get; set; }
    public Gee.Collection<Address> bcc { get; set; }

    public time_t time_received { get; private set; }
    public GLib.DateTime datetime_received {
        owned get {
            return new GLib.DateTime.from_unix_utc (time_received).to_local ();
        }
    }

    //@TODO add display_subject which removes Re:
    public string subject { get; construct set; }
    public Gee.List <string> references { get; set; }
    public Gee.List <string> in_reply_to { get; set; }
    public string id { get; construct set; }

    public string html_content { get; set; }
    public string plain_text_content { get; set; }
    public bool has_attachment { get { return false; } } //@TODO

    public string text { get; set; default = "BLA"; }

    public Message (
            void* mailcore_message,
            Address from,
            Address sender,
            Gee.Collection <Address> to,
            Gee.Collection <Address> cc,
            Gee.Collection <Address> bcc,
            string subject,
            time_t time_received,
            Gee.List <string> references,
            Gee.List <string> in_reply_to,
            string id,
            uint uid,
            uint modification_sequence,
            bool seen,
            bool flagged,
            bool deleted,
            bool draft
        ) {

        Object (
            mailcore_message: mailcore_message,
            from: from,
            sender: sender,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject.dup (),
            references: references,
            in_reply_to: in_reply_to,
            id: id.dup (),
            uid: uid,
            modification_sequence: modification_sequence,
            seen: seen,
            flagged: flagged,
            deleted: deleted,
            draft: draft
        );

        this.time_received = time_received;
    }

    public Message.for_sending (
            Gee.Collection <Address> to,
            Gee.Collection <Address> cc,
            Gee.Collection <Address> bcc,
            string subject,
            string text
        ) {

        Object (
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            text: text
        );
    }
    
    public Message.for_replying (
            Gee.Collection <Address> to,
            Gee.Collection <Address> cc,
            Gee.Collection <Address> bcc,
            string subject,
            Gee.List <string> references,
            Gee.List <string> in_reply_to,
            string text
        ) {
          
        Object (
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            references: references,
            in_reply_to: in_reply_to,
            text: text
        );
    } 

    public Message.for_flag_updating (
            void* mailcore_message,
            string id,
            uint uid,
            uint modification_sequence,
            bool seen,
            bool flagged,
            bool deleted,
            bool draft
        ) {
        Object (
            mailcore_message: mailcore_message,
            id: id.dup (),
            uid: uid,
            modification_sequence: modification_sequence,
            seen: seen,
            flagged: flagged,
            deleted: deleted,
            draft: draft
        );
    }
}
