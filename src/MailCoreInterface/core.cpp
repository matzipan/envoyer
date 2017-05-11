/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
#include <MailCore/MCIMAPSession.h>
#include <MailCore/MCIMAPFolder.h>
#include <glib.h>
#include "envoyer.h"
 
extern "C" void* mail_core_interface_connect(gchar* username, gchar* password) {
    auto session = new mailcore::IMAPSession();

    session->setUsername (new mailcore::String(username));
    session->setPassword (new mailcore::String(password));
    session->setHostname (new mailcore::String("imap.gmail.com"));
    session->setPort (993);
    session->setConnectionType (mailcore::ConnectionTypeTLS);
    
    
    //@TODO also close the connection?
    return session;
}

extern "C" void* mail_core_interface_fetch_folders(mailcore::IMAPSession* session) {
    mailcore::ErrorCode error; //@TODO check error

    mailcore::Array* folders = session->fetchAllFolders (&error);
    
    GList *list = NULL;

    for(uint i = 0 ; i < folders->count() ; i++) {
        mailcore::IMAPFolder* folder = (mailcore::IMAPFolder*) folders->objectAtIndex(i);
        
        if ((folder->flags() & mailcore::IMAPFolderFlagNoSelect) != 0) {
            continue;
        }
        
        EnvoyerFolderStruct* folder_struct = (EnvoyerFolderStruct*) g_malloc(sizeof(EnvoyerFolderStruct));
        folder_struct->name = folder->path()->UTF8Characters(); //@TODO copy this again
        folder_struct->flags = folder->flags();
        list = g_list_append (list, folder_struct);
    }
    
    return list;  
    
    //@TODO might have to release folders    
}
