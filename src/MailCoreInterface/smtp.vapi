namespace MailCoreInterface.Smtp {
    void* connect (string username, string password);
    void send_message (void* session, Envoyer.Models.Message message);


}
