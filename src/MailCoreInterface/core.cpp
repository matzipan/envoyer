#include <iostream>
#include <MailCore/MCIMAPSession.h>
#include <glib.h>
 
extern "C" void* mail_core_interface_connect(gchar* username, gchar* password) {
    auto session = new mailcore::IMAPSession();

    session->setUsername(new mailcore::String(username));
    session->setPassword(new mailcore::String(password));
    session->setHostname(new mailcore::String("imap.gmail.com"));
    session->setPort(993);
    session->setConnectionType(mailcore::ConnectionTypeTLS);
    
    return session;
}

extern "C" void mail_core_interface_fetch(mailcore::IMAPSession* session) {
    mailcore::ErrorCode error;

    mailcore::Array * folders = session->fetchAllFolders(&error);

    printf("%s", MCUTF8DESC(folders));

    auto uidRange = mailcore::IndexSet::indexSetWithRange(mailcore::RangeMake(1, UINT64_MAX));

    mailcore::Array * messages = session->fetchMessagesByUID(new mailcore::String("INBOX"), mailcore::IMAPMessagesRequestKindHeaders, uidRange, NULL, &error);

    printf("%s", MCUTF8DESC(messages));
    
}
