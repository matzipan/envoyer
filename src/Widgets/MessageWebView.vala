public class Envoyer.Widgets.MessageWebView : WebKit.WebView {
    private static uint web_view_id = 0;

    class construct {
        WebKit.WebContext.get_default ().initialize_web_extensions.connect (on_initialize_web_extensions);
    }
    
    private static void on_initialize_web_extensions (WebKit.WebContext context) {
        context.set_web_extensions_directory ("./"); //@TODO use something better here ... GResource?
        context.set_web_extensions_initialization_user_data (new GLib.Variant.uint32 (web_view_id));
    }

    private uint instance_web_view_id;
    private Envoyer.Services.IMessageViewerExtension bus = null;
    
    public MessageWebView () {
        // storing the corresponding web view id for this instance and generating a new one
        instance_web_view_id = web_view_id;
        web_view_id++;
        
        setup_dbus ();
        build_ui ();
    }

    private void setup_dbus () {
        GLib.Bus.watch_name(
            BusType.SESSION,
            "io.elementary.envoyer.MessageViewerExtension.id%u".printf(instance_web_view_id),
            BusNameWatcherFlags.NONE,
            on_extension_appeared,
            null
        );
    }
    
    private void on_extension_appeared(GLib.DBusConnection connection, string name, string owner) {
        try {
            bus = connection.get_proxy_sync(
                "io.elementary.envoyer.MessageViewerExtension.id%u".printf(instance_web_view_id),
                "/io/elementary/envoyer/MesssageViewerExtension",
                GLib.DBusProxyFlags.NONE,
                null
            );
            
            //@TODO this needs to be recalculated each time the width of the webview changes
            set_size_request (-1, (int) bus.get_height ()); //@TODO make this nicer and avoid flicker: currently this happens after the widget is first drawn so maybe hide it?
            debug ("Setting webview height to %u", bus.get_height ());
        } catch (IOError error) {
            warning("There was a problem connecting to web extension: %s", error.message);
            throw error;
        }
    }

    public void build_ui () {
        expand = true;
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        minimum_width = 400;
        natural_width = int.max (natural_width, minimum_width);
    }
}
