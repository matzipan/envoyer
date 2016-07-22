public class Envoyer.Models.Message : GLib.Object {
    private Camel.FolderThreadNode message_node;
    private Camel.MimeMessage mime_message;
    private Camel.MessageInfo message_info { get { return message_node.message; } }
    
    public GLib.DateTime datetime { 
        owned get { 
            return new GLib.DateTime.from_unix_utc (mime_message.date).to_local ();
        } 
    }
    
    public Envoyer.Models.Address from { owned get { return get_address_from_camel(mime_message.from, 0); } }
    public Gee.Collection<Envoyer.Models.Address> to { owned get { return get_addresses_collection_from_camel(mime_message.recipients.get(Camel.RECIPIENT_TYPE_TO)); } }
    public Gee.Collection<Envoyer.Models.Address> cc { owned get { return get_addresses_collection_from_camel(mime_message.recipients.get(Camel.RECIPIENT_TYPE_CC)); } }
    public Gee.Collection<Envoyer.Models.Address> bcc { owned get { return get_addresses_collection_from_camel(mime_message.recipients.get(Camel.RECIPIENT_TYPE_BCC));} }

    public string content { owned get { return Envoyer.Parsers.ParserRegistry.parse_mime_message (mime_message); } }
    public bool has_attachment { get { return Envoyer.Parsers.ParserHelper.has_attachment (mime_message); } }

    public Message (Camel.FolderThreadNode message_node, Envoyer.Models.Folder folder) {
        this.message_node = message_node;
        
        mime_message = folder.get_mime_message (message_info.uid);
    }

    private Envoyer.Models.Address get_address_from_camel (Camel.InternetAddress internet_address, int index) {
        string temp_name;
        string temp_email; 
        
        internet_address.get(index, out temp_name, out temp_email);
        
        return new Envoyer.Models.Address (temp_name, temp_email);
    }
    
    private Gee.Collection<Envoyer.Models.Address> get_addresses_collection_from_camel (Camel.InternetAddress internet_address) {
        var len = ((Camel.Address) internet_address).length();
        var list = new Gee.ArrayList<Envoyer.Models.Address> ();
    
        for (uint i=0; i < len; i++) {
            list.add(get_address_from_camel(internet_address, (int) i));
        }
        
        return list;
    }
}
