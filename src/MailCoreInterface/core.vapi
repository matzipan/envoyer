namespace MailCoreInterface {
    void* connect (string username, string password);
    GLib.List<Envoyer.FolderStruct*> fetch_folders (void* session);
}