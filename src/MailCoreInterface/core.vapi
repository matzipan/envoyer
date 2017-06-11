namespace MailCoreInterface {
    void* imap_connect (string username, string password);
    Gee.Collection<Envoyer.Models.Folder> imap_fetch_folders (void* session);
    Gee.Collection<Envoyer.Models.Message> imap_fetch_messages (void* session, string folder);
    string imap_get_html_for_message (void* session, string folder, Envoyer.Models.Message message);
    
    
    void* smtp_connect (string username, string password);
    void smtp_send_message (void* session, Envoyer.Models.Message message);


}