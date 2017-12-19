/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#include <MailCore/MCIMAPAsyncSession.h>
#include <glib.h>
#include "envoyer.h"

mailcore::AutoreleasePool * imap_pool; //@TODO clear pool

extern "C" void* mail_core_interface_imap_connect (gchar* username, gchar* access_token) {
    imap_pool = new mailcore::AutoreleasePool();

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
