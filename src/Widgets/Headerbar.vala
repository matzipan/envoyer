public class Mail.Headerbar : Gtk.HeaderBar {

    public Headerbar () {
        build_ui ();
    }

    private void build_ui () {
        set_show_close_button (true);
        
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), CUSTOM_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

     private const string CUSTOM_STYLESHEET = """
            @define-color colorPrimary #695E56;
            .titlebar .label  {
                color: #DEDBDA;
            }
         """;
}
