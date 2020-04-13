[CCode (cheader_filename = "src/MailCoreInterface/imap.h")]
namespace MailCoreInterface.Imap {
    void* connect (string username, string password);
    void  update_access_token (void* session, string access_token);
    [CCode (finish_name = "mail_core_interface_imap_fetch_data_for_message_part_finish")]
    public async GLib.Bytes fetch_data_for_message_part (void* session, string folder, uint64 uid, string part_id, int64 encoding);
    [CCode (finish_name = "mail_core_interface_imap_fetch_folders_finish")]
    public async Gee.Collection<Envoyer.Models.Folder> fetch_folders (void* session);
    [CCode (finish_name = "mail_core_interface_imap_fetch_messages_finish")]
    public async Gee.Collection<Envoyer.Models.Message> fetch_messages (void* session, string folder, uint64 starting_uid_value, uint64 end_uid_value, bool flags_only);
    [CCode (finish_name = "mail_core_interface_imap_move_messages_finish")]
    public async bool move_messages (void* session, string source_folder, Gee.List<uint64> message_uids, string destination_folder);
    [CCode (finish_name = "mail_core_interface_imap_get_message_uids_for_folder_finish")]
    public async Gee.Collection<Envoyer.Util.Range> get_message_uids_for_folder (void* session, string folder);
    [CCode (finish_name = "mail_core_interface_imap_get_html_for_message_finish")]
    public async string get_html_for_message (void* session, string folder, Envoyer.Models.Message message);
    [CCode (finish_name = "mail_core_interface_imap_get_plain_text_for_message_finish")]
    public async string get_plain_text_for_message (void* session, string folder, Envoyer.Models.Message message);
    [CCode (finish_name = "mail_core_interface_imap_idle_listener_finish")]
    public async void idle_listener (void* session, string folder, uint64 id);
}
