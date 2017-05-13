namespace MailCoreInterface {
    void* connect (string username, string password);
    Gee.LinkedList<Envoyer.Models.Folder> fetch_folders (void* session);
}