/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

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
        connect_signals ();
    }

    private void setup_dbus () {
        GLib.Bus.watch_name(
            BusType.SESSION,
            "%s.MessageViewerExtension.id%u".printf(Constants.PROJECT_FQDN, instance_web_view_id),
            BusNameWatcherFlags.NONE,
            on_extension_appeared,
            null
        );
    }
    
    private void on_extension_appeared(GLib.DBusConnection connection, string name, string owner) {
        try {
            bus = connection.get_proxy_sync(
                "%s.MessageViewerExtension.id%u".printf(Constants.PROJECT_FQDN, instance_web_view_id),
                "%s/MesssageViewerExtension".printf(Constants.DBUS_OBJECTS),
                GLib.DBusProxyFlags.NONE,
                null
            );
            
            size_update_async ();
        } catch (IOError error) {
            warning("There was a problem connecting to web extension: %s", error.message);
            throw error;
        }
    }
    
    public async void size_update_async () {
        if (bus == null) {
            return;
        }
        
        var height = bus.get_height ();
        
        debug ("Setting webview height to %u", height);
        set_size_request (-1, (int) height);
    }

    public void build_ui () {
        expand = true;
    }
    
    public void connect_signals () {
        size_allocate.connect (size_update_async);
        context_menu.connect (setup_context_menu);
    }
    
    public bool setup_context_menu (WebKit.ContextMenu context_menu, Gdk.Event event, WebKit.HitTestResult hit_test_result) {
        context_menu.remove_all ();
        
        if ((hit_test_result.context & WebKit.HitTestResultContext.LINK) != 0) {
            if (hit_test_result.link_uri.has_prefix ("mailto:")) {
                var action = new Gtk.Action ("copy email", "Copy _Email Address", null, null);
                
                action.activate.connect (() => {
                    var clipboard = Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD);
                    clipboard.set_text (hit_test_result.link_uri.substring ("mailto:".length, -1), -1);
                    clipboard.store ();
                });
                
                context_menu.append (new WebKit.ContextMenuItem (action));
            } else {
                context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.COPY_LINK_TO_CLIPBOARD));
            }
        }
        
        if ((hit_test_result.context & WebKit.HitTestResultContext.DOCUMENT) != 0) {
            context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.SELECT_ALL));
        }
        
        if ((hit_test_result.context & WebKit.HitTestResultContext.IMAGE) != 0) {
            context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.DOWNLOAD_IMAGE_TO_DISK));
            context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.COPY_IMAGE_TO_CLIPBOARD));
        }
        
        if ((hit_test_result.context & WebKit.HitTestResultContext.SELECTION) != 0) {
            context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.COPY));
            
            if ((hit_test_result.context & WebKit.HitTestResultContext.EDITABLE) != 0) {
                context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.CUT));
            }
        }
        
        if ((hit_test_result.context & WebKit.HitTestResultContext.EDITABLE) != 0) {
            context_menu.append (new WebKit.ContextMenuItem.from_stock_action (WebKit.ContextMenuAction.PASTE));
        }
       
        return false;        
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        minimum_width = 400;
        natural_width = int.max (natural_width, minimum_width);
    }
}
