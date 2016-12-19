/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.Parsers.TextHtmlParser : Envoyer.Parsers.IParser, GLib.Object {
    public const string mime_type = "text/html";

    private Camel.MimePart mime_part;

    public TextHtmlParser (Camel.MimePart mime_part) {
        assert(mime_part.get_content_type ().simple ().down () == mime_type);

        this.mime_part = mime_part;
    }

    public string get_content () {
        var os = new GLib.MemoryOutputStream.resizable ();

        mime_part.content.decode_to_output_stream_sync (os);
        os.close ();

        return (string) os.steal_data ();
    }
}
