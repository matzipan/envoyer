/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Models.Message : GLib.Object {
    public Envoyer.Models.Identity identity;
    public Envoyer.Models.Folder folder;

    //@TODO find a way to either integrate this or get rid of it. needed for html fetching
    public void* mailcore_message { get; construct set; }
    public Envoyer.Models.Address from { get; set; }
    public Envoyer.Models.Address sender { get; construct set; }
    public Gee.Collection<Envoyer.Models.Address> to { get; construct set; }
    public Gee.Collection<Envoyer.Models.Address> cc { get; construct set; }
    public Gee.Collection<Envoyer.Models.Address> bcc { get; construct set; }
    
    public time_t time_received { get; private set; } 
    public GLib.DateTime datetime_received { 
        owned get { 
            return new GLib.DateTime.from_unix_utc (time_received).to_local ();
        } 
    }

    //@TODO add display_subject which removes Re:
    public string subject { get; construct set; }
    public Gee.Collection<string> references { get; construct set; }
    public string id { get; construct set; }

    public string content { owned get { return identity.get_html_for_message (this); } }
    public bool has_attachment { get { return false; } } //@TODO
    
    public string text { get; set; default = "BLA"; }

    public Message (
            void* mailcore_message,
            Envoyer.Models.Address from, 
            Envoyer.Models.Address sender,
            Gee.Collection <Envoyer.Models.Address> to,
            Gee.Collection <Envoyer.Models.Address> cc,
            Gee.Collection <Envoyer.Models.Address> bcc, 
            string subject,
            time_t time_received,
            Gee.Collection <string> references, 
            string id
        ) {
        
        Object (
            mailcore_message: mailcore_message,
            from: from,
            sender: sender,
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            references: references,
            id: id.dup ()
        );
        
        this.time_received = time_received;
    }
    
    public Message.for_sending (
            Gee.Collection <Envoyer.Models.Address> to,
            Gee.Collection <Envoyer.Models.Address> cc,
            Gee.Collection <Envoyer.Models.Address> bcc, 
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
}
