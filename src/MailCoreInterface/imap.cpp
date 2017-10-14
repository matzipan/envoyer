/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#include <MailCore/MCIMAPAsyncSession.h>
#include <glib.h>
#include "envoyer.h"

mailcore::AutoreleasePool * pool; //@TODO clear pool

extern "C" void* mail_core_interface_imap_connect (gchar* username, gchar* password) {    
    pool = new mailcore::AutoreleasePool();

    auto session = new mailcore::IMAPAsyncSession ();

    session->setUsername (new mailcore::String (username));
    session->setPassword (new mailcore::String (password));
    session->setHostname (new mailcore::String ("imap.gmail.com"));
    session->setPort (993);
    session->setConnectionType (mailcore::ConnectionTypeTLS);

    //@TODO also close the connection?
    return session;
}

extern "C" const gchar* mail_core_interface_imap_get_html_for_message (mailcore::IMAPAsyncSession* session, gchar* folder_path, EnvoyerModelsMessage* envoyer_message) {
    mailcore::ErrorCode error; //@TODO check error

    // return session->htmlRendering ((mailcore::IMAPMessage *) envoyer_models_message_get_mailcore_message (envoyer_message), new mailcore::String (folder_path), &error)->UTF8Characters();
    return "";
}
