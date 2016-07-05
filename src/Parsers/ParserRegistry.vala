public class Envoyer.Parsers.ParserRegistry : GLib.Object {
    public static string parse_mime_message_as (Camel.MimeMessage mime_message, string mime_type) {
        return get_mime_message_parser (mime_message, mime_type.down ()).get_content ();
    }
    
    private static Envoyer.Parsers.IParser get_mime_message_parser (Camel.MimeMessage mime_message, string mime_type) {
        if (mime_type == Envoyer.Parsers.MultipartAlternativeParser.mime_type) {
            return new Envoyer.Parsers.MultipartAlternativeParser (mime_message);
        }
        
        //@TODO fallback
        assert_not_reached ();
    }
    
    public static string parse_mime_part_as (Camel.MimePart mime_part, string mime_type) {
        return get_mime_part_parser (mime_part, mime_type.down ()).get_content ();
    }
    
    private static Envoyer.Parsers.IParser get_mime_part_parser (Camel.MimePart mime_part, string mime_type) {
        if (mime_type == Envoyer.Parsers.TextHtmlParser.mime_type) {
            return new Envoyer.Parsers.TextHtmlParser (mime_part);
        }
        
        //@TODO fallback
        assert_not_reached ();
    }
}