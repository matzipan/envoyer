[CCode (cheader_filename = "src/MailCoreInterface/smtp.h")]
namespace MailCoreInterface.Smtp {
    void* connect (string username, string password);
    void  update_access_token (void* session, string access_token);
    [CCode (finish_name = "mail_core_interface_smtp_send_message_finish")]
    public async void send_message (void* session, Envoyer.Models.Message message);
}
