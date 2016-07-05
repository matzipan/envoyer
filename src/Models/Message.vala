

public class Envoyer.Models.Message : GLib.Object {
    private Camel.FolderThreadNode message_node;
    private Camel.MimeMessage mime_message;
    private Camel.MessageInfo message_info { get { return message_node.message; } }


    public string content {
        owned get {
            return Envoyer.Parsers.ParserRegistry.parse_mime_message_as (mime_message, mime_message.get_content_type ().simple ());

        }
    }

    public Message (Camel.FolderThreadNode message_node, Envoyer.Models.Folder folder) {
        this.message_node = message_node;
        
        mime_message = folder.get_mime_message (message_info.uid);
    }


}