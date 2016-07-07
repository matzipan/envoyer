
public class Envoyer.Parsers.MultipartAlternativeParser : Envoyer.Parsers.IParser, GLib.Object {
    public static const string mime_type = "multipart/alternative";

    private Camel.MimeMessage mime_message;

    public MultipartAlternativeParser (Camel.MimeMessage mime_message) {
        assert(mime_message.get_content_type ().simple ().down () == mime_type);

        this.mime_message = mime_message;
    }

    public string get_content () {
        Camel.MimePart best = null;
        var multipart = (Camel.Multipart) mime_message.get_content ();

        for(var i = 0; i < multipart.get_number (); i++) {
            var part = multipart.get_part (i);
            var data_wrapper = part.get_content ();

            //@TODO all this to check if it's empty, maybe find another way?
            var null_stream = new Camel.NullOutputStream ();
            data_wrapper.decode_to_output_stream_sync (null_stream);
            if(null_stream.get_bytes_written () == 0) {
                continue;
            }



    		var content_type = part.get_content_type ();
    		var mime_type = content_type.simple ();

    		if (!is_attachment (part) &&
                (
                    !content_type.is ("multipart", "related") ||
                    !related_display_part_is_attachment (part)
                ) && true
    		    /*( @TODO
                    e_mail_extension_registry_get_for_mime_type (reg, mime_type) ||
                    (
                        best == NULL &&
                        e_mail_extension_registry_get_fallback (reg, mime_type)
                    )
                )*/) {
    			best = part;
    		}
        }
        
        if (best != null) {
            var content_type = best.get_content_type ();
            var mime_type = "appliction/x-envoyer-fallback";
            
            if (content_type != null) {
                mime_type = content_type.simple ();
            }

            return Envoyer.Parsers.ParserRegistry.parse_mime_part_as (best, mime_type);
        } else {
            return Envoyer.Parsers.ParserRegistry.parse_mime_part_as (best, "multipart/mixed");
        }

        assert_not_reached ();
    }

    
    private static bool is_attachment (Camel.MimePart part) {
        var data_wrapper = part.get_content ();

    	if (data_wrapper == null) {
            //@TODO throw an error
        }
        
        var mime_type = data_wrapper.mime_type;

    	message ("Checking is_attachment %s/%s", data_wrapper.mime_type.type, data_wrapper.mime_type.subtype);
        
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

    private static bool related_display_part_is_attachment (Camel.MimePart part) {
        /*var display_part = e_mail_part_get_related_display_part (part, NULL);

    	return display_part && is_attachment (display_part);*/
        
        return false;
    }
    
    /*private static Camel.MimePart get_related_display_part (Camel.MimePart part) { @TODO
        CamelMultipart *mp;
    	CamelMimePart *body_part, *display_part = NULL;
    	CamelContentType *content_type;
    	const gchar *start;
    	gint i, nparts, displayid = 0;

    	mp = (CamelMultipart *) camel_medium_get_content ((CamelMedium *) part);

    	if (!CAMEL_IS_MULTIPART (mp))
    		return NULL;

    	nparts = camel_multipart_get_number (mp);
    	content_type = camel_mime_part_get_content_type (part);
    	start = camel_content_type_param (content_type, "start");
    	if (start && strlen (start) > 2) {
    		gint len;
    		const gchar *cid;*/

    		/* strip <>'s from CID */
    		/*len = strlen (start) - 2;
    		start++;

    		for (i = 0; i < nparts; i++) {
    			body_part = camel_multipart_get_part (mp, i);
    			cid = camel_mime_part_get_content_id (body_part);

    			if (cid && !strncmp (cid, start, len) && strlen (cid) == len) {
    				display_part = body_part;
    				displayid = i;
    				break;
    			}
    		}
    	} else {
    		display_part = camel_multipart_get_part (mp, 0);
    	}

    	if (out_displayid)
    		*out_displayid = displayid;

    	return display_part;
    }*/

}