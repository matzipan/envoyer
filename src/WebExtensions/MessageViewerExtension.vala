[CCode (cname = "G_MODULE_EXPORT webkit_web_extension_initialize_with_user_data", instance_pos = -1)]
void webkit_web_extension_initialize_with_user_data(WebKit.WebExtension extension, GLib.Variant id_variant) {
    var messageViewerServer = new Envoyer.Services.MessageViewerExtensionServer((uint) id_variant.get_uint32 ());
    extension.page_created.connect(messageViewerServer.on_page_created);
}