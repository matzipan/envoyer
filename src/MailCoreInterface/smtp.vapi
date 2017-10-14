namespace MailCoreInterface.Smtp {
    void* connect (string username, string password);
    [CCode (finish_name = "mail_core_interface_smtp_send_message_finish")]
    public async void send_message (void* session, Envoyer.Models.Message message);


}
