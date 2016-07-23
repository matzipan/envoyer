/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Parsers.ParserRegistry : GLib.Object {
    public static string parse_mime_message (Camel.MimeMessage mime_message) {
        return get_mime_message_parser (mime_message).get_content ();
    }
    
    private static Envoyer.Parsers.IParser get_mime_message_parser (Camel.MimeMessage mime_message) {
        var mime_type = mime_message.get_content_type ().simple ();
        
        if (mime_type.ascii_casecmp(Envoyer.Parsers.MultipartAlternativeParser.mime_type) == 0) {
            return new Envoyer.Parsers.MultipartAlternativeParser (mime_message);
        }
        
        //@TODO fallback
        assert_not_reached ();
    }
    
    public static string parse_mime_part_as (Camel.MimePart mime_part, string mime_type) {
        return get_mime_part_parser (mime_part, mime_type).get_content ();
    }
    
    private static Envoyer.Parsers.IParser get_mime_part_parser (Camel.MimePart mime_part, string mime_type) {        
        if (mime_type.ascii_casecmp(Envoyer.Parsers.TextHtmlParser.mime_type) == 0) {
            return new Envoyer.Parsers.TextHtmlParser (mime_part);
        }
        
        //@TODO fallback
        assert_not_reached ();
    }
    
    public static bool has_parser_for_mime_type (string mime_type) {        
        return
            mime_type.ascii_casecmp(Envoyer.Parsers.TextHtmlParser.mime_type) == 0 || 
            mime_type.ascii_casecmp(Envoyer.Parsers.MultipartAlternativeParser.mime_type) == 0;
    }
}
