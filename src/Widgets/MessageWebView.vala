/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class Envoyer.Widgets.MessageWebView : WebKit.WebView {
    private static uint web_view_id = 0;

    class construct {
        WebKit.WebContext.get_default ().set_process_model (WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES);
        WebKit.WebContext.get_default ().initialize_web_extensions.connect (on_initialize_web_extensions);
    }
    
    private static void on_initialize_web_extensions (WebKit.WebContext context) {
        context.set_web_extensions_directory ("./"); //@TODO use something better here ... GResource?
        context.set_web_extensions_initialization_user_data (new GLib.Variant.uint32 (web_view_id));
    }

    private uint instance_web_view_id;
    private Envoyer.Services.IMessageViewerExtension bus = null;

    public signal void link_mouse_in (string uri);
    public signal void link_mouse_out ();
    
    private string _document_font;
    public string document_font {
        get {
            return _document_font;
        }
        set {
            _document_font = value;
            Pango.FontDescription font = Pango.FontDescription.from_string(value);
            var temp_settings = get_settings ();
            temp_settings.default_font_family = font.get_family();
            temp_settings.default_font_size = font.get_size() / Pango.SCALE;
            set_settings (temp_settings);
        }
    }
    
    private string _monospace_font;
    public string monospace_font {
        get {
            return _monospace_font;
        }
        set {
            _monospace_font = value;
            Pango.FontDescription font = Pango.FontDescription.from_string(value);
            var temp_settings = get_settings ();
            temp_settings.monospace_font_family = font.get_family();
            temp_settings.default_monospace_font_size = font.get_size() / Pango.SCALE;
            set_settings (temp_settings);
        }
    }

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
        hexpand = true;
        can_focus = false;
    }
    
    public void connect_signals () {
        mouse_target_changed.connect (on_mouse_target_changed);
        size_allocate.connect (size_update_async);
        context_menu.connect (setup_context_menu);
        decide_policy.connect (on_decide_policy);
        gnome_settings.bind("document-font-name", this, "document-font", SettingsBindFlags.DEFAULT);
        gnome_settings.bind("monospace-font-name", this, "monospace-font", SettingsBindFlags.DEFAULT);
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
    
    public void load_html (string content, string? base_uri) {
        //@TODO improve the formatting, check pantheon-mail
        //@TODO add inline images

        var format = "<html>
                        <style>
                            body {
                                overflow-y: hidden; /* prevent vertical scrollbar */
                                font-size: 12px;
                            }
                            body > div {
                                overflow-wrap: break-word;
                                margin-right: 5px; /* prevent overlap with scrollbar */
                            }
                        </style>
                        <body>
                            <div>%s</div>
                        </body>
                      </html>";
        base.load_html(format.printf(content), base_uri);
    }

    private bool on_decide_policy (WebKit.PolicyDecision decision, WebKit.PolicyDecisionType type) {
        if (type == WebKit.PolicyDecisionType.NAVIGATION_ACTION || type == WebKit.PolicyDecisionType.NEW_WINDOW_ACTION)  {
            var navigation_decision = (WebKit.NavigationPolicyDecision) decision;

            if (navigation_decision.navigation_action.get_navigation_type () == WebKit.NavigationType.LINK_CLICKED) {
                decision.ignore ();

                var link = navigation_decision.request.uri;

                if (link.down().has_prefix("mailto:")) {
                    // @TODO compose woth navigation_decision.request.uri, strip the prefix
                } else {
                    if (!link.has_prefix("http://") && !link.has_prefix("https://")) {
                        link = "http://" + link;
                    }

                    try {
                        Gtk.show_uri(Envoyer.main_window.get_screen(), link, Gdk.CURRENT_TIME);
                    } catch (Error err) {
                        debug("Unable to open URL %s, reason: %s", link, err.message);
                    }
                }

                return true;
            }
        }

        return true;
    }

    private void on_mouse_target_changed (WebKit.HitTestResult hit_test_result, uint modifiers) {
        if (hit_test_result.context_is_link ()) {
            link_mouse_in (hit_test_result.get_link_uri ());
        } else {
            link_mouse_out ();
        }
    }
}
