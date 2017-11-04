namespace MailCoreInterface.Imap {
    void* connect (string username, string password);
    [CCode (finish_name = "mail_core_interface_imap_fetch_folders_finish")]
    public async Gee.Collection<Envoyer.Models.Folder> fetch_folders (void* session);
    [CCode (finish_name = "mail_core_interface_imap_fetch_messages_finish")]
    public async Gee.Collection<Envoyer.Models.Message> fetch_messages (void* session, string folder, uint starting_uid_value);
    [CCode (finish_name = "mail_core_interface_imap_get_html_for_message_finish")]
    public async string get_html_for_message (void* session, string folder, Envoyer.Models.Message message);
    [CCode (finish_name = "mail_core_interface_imap_idle_listener_finish")]
    public async void idle_listener (void* session, string folder, uint id);
}
