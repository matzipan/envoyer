namespace MailCoreInterface {
    void* connect (string username, string password);
    Gee.Collection<Envoyer.Models.Folder> fetch_folders (void* session);
    Gee.Collection<Envoyer.Models.Message> fetch_messages (void* session, string folder);
    string get_html_for_message (void* session, string folder, Envoyer.Models.Message message);

}