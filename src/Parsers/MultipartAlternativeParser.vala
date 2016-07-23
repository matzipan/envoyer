/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Parsers.MultipartAlternativeParser : Envoyer.Parsers.IParser, GLib.Object {
    public static const string mime_type = "multipart/alternative";

    private Camel.MimeMessage mime_message;

    public MultipartAlternativeParser (Camel.MimeMessage mime_message) {
        assert(mime_message.get_content_type ().simple ().ascii_casecmp(mime_type) == 0);

        this.mime_message = mime_message;
    }

    public string get_content () {
        Camel.MimePart best = null;
        var multipart = (Camel.Multipart) mime_message.get_content ();

        for(var i = 0; i < multipart.get_number (); i++) {
            var part = multipart.get_part (i);
            var data_wrapper = part.get_content ();

            // check if part not empty
            var null_stream = new Camel.NullOutputStream ();
            data_wrapper.decode_to_output_stream_sync (null_stream);
            if(null_stream.get_bytes_written () == 0) {
                continue;
            }

    		var mime_type = part.get_content_type ().simple ();

    		if (!Envoyer.Parsers.ParserHelper.is_attachment (part) &&
                (
                    mime_type.ascii_casecmp("multipart/related") != 0 ||
                    !Envoyer.Parsers.ParserHelper.related_display_part_is_attachment (part)
                ) &&
    		    Envoyer.Parsers.ParserRegistry.has_parser_for_mime_type (mime_type)
                // Evolution includes here some extra magic for falling back on parsers for other mime types, might not be necessary
               ) {
    			best = part;
    		}
        }
        
        if (best == null) {
            return Envoyer.Parsers.ParserRegistry.parse_mime_part_as (best, "multipart/mixed"); //@TODO implement multipart/mixed
        } else {
            return Envoyer.Parsers.ParserRegistry.parse_mime_part_as (best, best.get_content_type ().simple ());
        }

        assert_not_reached ();
    }
}
