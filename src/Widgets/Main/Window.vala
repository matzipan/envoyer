/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

using Envoyer.Globals.Main;
using Envoyer.Globals.Application;

namespace Envoyer.Globals.Main {
    public Envoyer.Widgets.Main.Sidebar.Wrapper sidebar;
    public Envoyer.Widgets.Main.FolderConversationsList folder_conversations_list;
    public Envoyer.Widgets.Main.ConversationViewer conversation_viewer;
    public Envoyer.Widgets.Main.Window main_window;
}

public class Envoyer.Widgets.Main.Window : Gtk.ApplicationWindow {
    public Envoyer.Controllers.Application application { get; construct set; }

    private Headerbar headerbar;
    private Envoyer.FutureGranite.ThreePane three_pane;

    private const string STYLESHEET = """
        EnvoyerWidgetsMainFolderConversationItem {
            border-bottom: 1px solid #efefef;
        }

        EnvoyerWidgetsMainMessageViewer {
            border-bottom: 1px solid #efefef;
        }

        .unread .subject, .unread_dot {
            color: #0777D4;
        }

        EnvoyerWidgetsMainConversationViewer GtkListBox, EnvoyerWidgetsMainSidebarWrapper GtkListBox {
            background: #eee;
        }

        EnvoyerWidgetsMainConversationViewer GtkListBoxRow {
            background: #fff;
        }

        dialog.welcome-dialog {
            background: #fff;
        }

        dialog.welcome-dialog headerbar {
            background: #fff;
        }

        /* This should probably be in basalt */
        row:selected button.disclosure-button {
            background: none;
        }
    """;

    private const string FALLBACK_STYLESHEET = """
        .envoyer-swipe-box {
            background: linear-gradient(to right, #a8040d 0, #f00713 6px, #f00713 100%);
        }

        .envoyer-swipe-action-icon {
            color: #fff;
        }
    """;

    public Window (Envoyer.Controllers.Application app) {
        Object (application: app);

        build_ui ();
        connect_signals ();
        load_settings ();
    }

	private void load_settings () {
        resize (settings.window_width, settings.window_height);
        //@TODO settings window_maximize
		/*three_pane.position for both inner borders = settings.panel_size; #@ TODO*/
	}

    private void build_ui () {
        var icon_theme = Gtk.IconTheme.get_default ();
        icon_theme.append_search_path (Constants.PKGDATADIR + "/icons/");

        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), FALLBACK_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK);

        headerbar = new Headerbar ();
        headerbar.set_title (Constants.APP_NAME);
        set_titlebar (headerbar);

        sidebar = new Sidebar.Wrapper ();
        folder_conversations_list = new FolderConversationsList ();
        conversation_viewer = new ConversationViewer ();

        three_pane = new Envoyer.FutureGranite.ThreePane.with_children (sidebar, folder_conversations_list, conversation_viewer);

		    move (settings.position_x, settings.position_y);
        add (three_pane);
    }

    private void connect_signals () {
        var close_action = new SimpleAction ("close-action", null);
        close_action.activate.connect (request_close);
        add_action (close_action);
        application.set_accels_for_action ("win.close-action", {"<Ctrl>Q"});

        application.session_up.connect (session_up_handler);

        /*var new_action = new SimpleAction ("new-action", null);
        new_action.activate.connect (new_page);
        add_action (new_action);
        app.set_accels_for_action ("win.new-action", {"<Ctrl>N"});*/
    }

    private void session_up_handler () {
        show_all ();
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

    	folder_conversations_list.grab_focus ();
	}
}
