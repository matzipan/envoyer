

public class Envoyer.Models.Message : GLib.Object {
    private Camel.FolderThreadNode message_node;
    private Camel.MimeMessage mime_message;
    private Camel.MessageInfo message_info { get { return message_node.message; } }
    
    public string content { 
        owned get {
            var os = new GLib.MemoryOutputStream.resizable ();

            ((Camel.DataWrapper) mime_message).decode_to_output_stream_sync (os);
            os.close ();

            return (string) os.steal_data ();
        }
    }

    public Message (Camel.FolderThreadNode message_node, Envoyer.Models.Folder folder) {
        this.message_node = message_node;
        
        mime_message = folder.get_mime_message (message_info.uid);
        

    }


}