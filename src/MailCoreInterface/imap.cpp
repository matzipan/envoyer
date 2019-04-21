/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#include <MailCore/MCIMAPAsyncSession.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"


extern "C" void* mail_core_interface_imap_connect (gchar* username, gchar* access_token) {

    auto session = new mailcore::IMAPAsyncSession ();

    session->setUsername (new mailcore::String (username));
    session->setAuthType(mailcore::AuthTypeXOAuth2);
    session->setOAuth2Token(new mailcore::String (access_token));
    session->setHostname (new mailcore::String ("imap.gmail.com"));
    session->setPort (993);
    session->setConnectionType (mailcore::ConnectionTypeTLS);

    //@TODO also close the connection?
    return session;
}

extern "C" void* mail_core_interface_imap_update_access_token (void* session, gchar* access_token) {
    auto imap_async_session = (mailcore::IMAPAsyncSession*) session;

    imap_async_session->setOAuth2Token (new mailcore::String (access_token));
}
