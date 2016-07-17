public class Envoyer.Widgets.MessageViewer : Gtk.ListBoxRow {
    private Envoyer.Widgets.MessageWebView webview;
    
    private Envoyer.Models.Message message_item;

    public MessageViewer (Envoyer.Models.Message message_item) {
        this.message_item = message_item;

        build_ui ();
        load_data ();
    }

    private void build_ui () {
        margin = 10;
        get_style_context().add_class("card");

        expand = true;

        webview = new Envoyer.Widgets.MessageWebView ();

        add (webview);
        show_all ();
    }

    private void load_data () {
        webview.load_html (message_item.content, null);
    }
}