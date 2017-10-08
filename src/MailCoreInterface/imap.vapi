namespace MailCoreInterface.Imap {
    void* connect (string username, string password);
    [CCode (finish_name = "mail_core_interface_imap_fetch_folders_finish")]
    public async Gee.Collection<Envoyer.Models.Folder> fetch_folders (void* session);
    Gee.Collection<Envoyer.Models.Message> fetch_messages (void* session, string folder);
    string get_html_for_message (void* session, string folder, Envoyer.Models.Message message);

}
