/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <MailCore/MCIMAPAsyncSession.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"

#if CONSTANTS_DEBUG_LOGGING
#import <libetpan/libetpan.h>

void mailcore_logger(int direction, const char * incoming_string, size_t size) {
    /* Direction is 1 for sending, 0 for receiving, -1 when it does not apply */

    char *local_string = (char*) malloc(size + 1);
    strncpy(local_string, incoming_string, size);
    local_string[size] = 0;
    if (direction == 1) {
        printf("%s\n", local_string);
    } else if (direction == 0) {
        printf("%s\n", local_string);
    } else {
        printf("%s\n", local_string);
    }
    free(local_string);
}

extern int MCLogEnabled;
extern int mailstream_debug;
#endif


extern "C" void* mail_core_interface_imap_connect (gchar* username, gchar* access_token) {
    #if CONSTANTS_DEBUG_LOGGING
    MCLogEnabled = 1;
    mailstream_debug = 1;
    mailstream_logger = mailcore_logger;
    #endif

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
