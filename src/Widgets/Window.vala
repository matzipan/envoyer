/*
 * Copyright 2011-2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.Window : Gtk.ApplicationWindow {
    public signal void session_up ();

    private Envoyer.Widgets.Headerbar headerbar;
    private Envoyer.FutureGranite.ThreePane three_pane;
    
    private const string CUSTOM_STYLESHEET = """
        .from {
            font-weight: bold;
        }
    """;

    public Window (Gtk.Application app) {
		Object (application: app);

	    build_ui ();
        connect_signals (app);
        load_settings ();
    }
    
	private void load_settings () {
        resize (settings.window_width, settings.window_height);
        //@TODO settings window_maximize
		/*three_pane.position for both inner borders = settings.panel_size; #@ TODO*/
	}
    
    private void build_ui () {
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), CUSTOM_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        headerbar = new Envoyer.Widgets.Headerbar ();
        headerbar.set_title (Constants.APP_NAME);
        set_titlebar (headerbar);

        sidebar = new Envoyer.Widgets.Sidebar ();
        folder_threads_list = new Envoyer.Widgets.FolderThreadsList ();
        conversation_viewer = new Envoyer.Widgets.ConversationViewer ();
        
        three_pane = new Envoyer.FutureGranite.ThreePane.with_children (sidebar, folder_threads_list, conversation_viewer);

		move (settings.position_x, settings.position_y);
        add (three_pane);
        show_all ();
    }

    private void connect_signals (Gtk.Application app) {
        var close_action = new SimpleAction ("close-action", null);
        close_action.activate.connect (request_close);
        add_action (close_action);
        app.set_accels_for_action ("win.close-action", {"<Ctrl>Q"});

        /*var new_action = new SimpleAction ("new-action", null);
        new_action.activate.connect (new_page);
        add_action (new_action);
        app.set_accels_for_action ("win.new-action", {"<Ctrl>N"});*/
        
        session_up.connect(() => { sidebar.session_up (); });
    }
    
    protected override bool delete_event (Gdk.EventAny event) {
        int width;
        int height;
        int x;
        int y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.position_x = x;
        settings.position_y = y;
        settings.window_width = width;
        settings.window_height = height;

        return false;
    }


    private void request_close () {
        close ();
    }

    public void show_app () {
		show ();
    	present ();

    	folder_threads_list.grab_focus ();
	}
}
