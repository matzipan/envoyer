/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.Main.Headerbar : Gtk.HeaderBar {
    private Gtk.Button compose_button;
    private Gtk.MenuButton menu_button;

    public Headerbar () {
        build_ui ();
        
        connect_signals ();
    }

    private void build_ui () {
        set_show_close_button (true);
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), CUSTOM_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                
        // @TODO use this instead of set_theming when granite gets fixed 
        //var headerbar_color = Gdk.RGBA();
        //headerbar_color.parse("#F7AC37");
        //Granite.Widgets.Utils.set_color_primary (this, headerbar_color);
                
        compose_button = new Gtk.Button.from_icon_name ("mail-message-new", Gtk.IconSize.LARGE_TOOLBAR);
        compose_button.tooltip_text = (_("Compose message")); //@TODO + Key.COMPOSE.to_string ());
        pack_start (compose_button);
        
        menu_button = new Gtk.MenuButton ();
        menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
        pack_end (menu_button);

        var menu = new Gtk.Menu ();
        menu.add (new Gtk.MenuItem.with_label (_("Accounts")));
        menu.add (new Gtk.MenuItem.with_label (_("Quit")));
        menu.show_all ();
        menu_button.set_popup (menu);
    }
    
    private void connect_signals () {
        /*compose_button.clicked.connect ();*/
    }
    
    private const string CUSTOM_STYLESHEET = """
        @define-color colorPrimary #F7AC37;
        @define-color textColorPrimary rgba(30,30,30,0.7);
        
    """;
}
