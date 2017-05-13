namespace MailCoreInterface {
    void* connect (string username, string password);
    Gee.Collection<Envoyer.Models.Folder> fetch_folders (void* session);
    Gee.Collection<Envoyer.Models.Message> fetch_messages (void* session);
}