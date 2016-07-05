public class Envoyer.Widgets.MessageViewer : Gtk.ListBoxRow {
    private WebKit.WebView webview;
    
    private Envoyer.Models.Message message_item;
    
    public MessageViewer (Envoyer.Models.Message message_item) {
        this.message_item = message_item;

        build_ui ();
        load_data ();
    }

    private void build_ui () {
        webview = new WebKit.WebView ();
        
        webview.expand = true;
        webview.set_size_request (200,500); //@TODO fix this

        add (webview);

        show_all ();
    }
    
    private void load_data () {
        webview.load_html (message_item.content, null);
    }
}