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
    public void* mailcore_message { get; private set; }
    public Envoyer.Models.Address from { get; private set; }
    public Envoyer.Models.Address sender { get; private set; }
    public Gee.Collection<Envoyer.Models.Address> to { get; private set; }
    public Gee.Collection<Envoyer.Models.Address> cc { get; private set; }
    public Gee.Collection<Envoyer.Models.Address> bcc { get; private set; }
    
    public time_t time_received { get; private set; } 
    public GLib.DateTime datetime_received { 
        owned get { 
            return new GLib.DateTime.from_unix_utc (_time_received).to_local ();
        } 
    }

    //@TODO add display_subject which removes Re:
    public string subject { get; private set; }
    public Gee.Collection<string> references { get; private set; }
    public string id { get; private set; }

    public string content { owned get { return identity.get_html_for_message (this); } }
    public bool has_attachment { get { return false; } } //@TODO

    public Message (
            void* mailcore_message,
            Envoyer.Models.Address from, 
            Envoyer.Models.Address sender,
            Gee.Collection<Envoyer.Models.Address> to,
            Gee.Collection<Envoyer.Models.Address> cc,
            Gee.Collection<Envoyer.Models.Address> bcc, 
            string subject,
            time_t time_received,
            Gee.Collection<string> references, 
            string id
        ) {
            
        this.mailcore_message = mailcore_message;
        this.from = from;
        this.sender = sender;
        this.to = to;
        this.cc = cc;
        this.bcc = bcc;
        this._time_received = time_received;
        this.subject = subject;
        this.references = references;
        this.id = id.dup ();
    }
}
