/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Parsers.ParserHelper : GLib.Object {
    public static bool is_attachment (Camel.MimePart part) {
        var data_wrapper = part.get_content ();

	    if (data_wrapper == null) {
            //@TODO throw an error
        }
        
        var mime_type = data_wrapper.mime_type;

	    debug ("Checking is_attachment %s/%s", data_wrapper.mime_type.type, data_wrapper.mime_type.subtype);
        
        return !(
                    mime_type.is ("multipart", "*") ||
                    mime_type.is ("application", "x-pkcs7-mime") ||
                    mime_type.is ("application", "pkcs7-mime") ||
                    mime_type.is ("application", "x-inlinepgp-signed") ||
            		mime_type.is ("application", "x-inlinepgp-encrypted") ||
                    mime_type.is ("x-evolution", "evolution-rss-feed") ||
                    mime_type.is ("text", "calendar") ||
                    mime_type.is ("text", "x-calendar") ||
                    (mime_type.is ("text", "*") && part.get_filename () == null)
                );
    }
    
    public static bool has_attachment (Camel.MimeMessage mime_message) { 
        if (!mime_message.get_content_type ().is ("multipart", "*")) {
            return false;
        }
    
        var multipart = (Camel.Multipart) mime_message.get_content ();

        for(var i = 0; i < multipart.get_number (); i++) {
            var part = multipart.get_part (i);
            
            if (Envoyer.Parsers.ParserHelper.is_attachment (part)) {
                return true;
            }
        }
        
        return false;
    }
    
    
        public static bool related_display_part_is_attachment (Camel.MimePart part) {
            var display_part = get_related_display_part (part);
    
        	return display_part != null && is_attachment (display_part);
        }
        
        private static Camel.MimePart get_related_display_part (Camel.MimePart part) {
        	Camel.MimePart display_part = null;
    
        	Camel.Multipart multipart = (Camel.Multipart) part.get_content ();
    
        	var start = part.get_content_type ().param ("start");
        	
        	// Does the param contain angle brackets? Let's strip them
        	if (start.length > 2) {
        	    var position = start.last_index_of(">");
        		var stripped_start = start.splice(position, position+1).splice(0, 1);
    
        		for (var i = 0; i < multipart.get_number (); i++) {
        			var body_part = multipart.get_part (i);
        			var content_id = body_part.get_content_id ();
    
        			if (content_id != null && content_id == stripped_start) {
        				display_part = body_part;
        				break;
        			}
        		}
        	} else {
        		display_part = multipart.get_part (0);
        	}
    
        	return display_part;
        }
}
