/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.Headerbar : Gtk.HeaderBar {

    public Headerbar () {
        build_ui ();
    }

    private void build_ui () {
        set_show_close_button (true);
                
        // @TODO use this instead of set_theming when granite gets fixed 
        //var headerbar_color = Gdk.RGBA();
        //headerbar_color.parse("#F7AC37");
        //Granite.Widgets.Utils.set_color_primary (this, headerbar_color);
        
        
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), CUSTOM_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    
    private const string CUSTOM_STYLESHEET = """
        @define-color colorPrimary #F7AC37;
        @define-color textColorPrimary rgba(30,30,30,0.7);
    """;
}
