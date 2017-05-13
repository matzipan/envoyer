/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
#include <MailCore/MCIMAPSession.h>
#include <MailCore/MCIMAPFolder.h>
#include <MailCore/MCIMAPFolderStatus.h>
#include <glib.h>
#include <gee.h>
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
    
    GeeLinkedList *list = gee_linked_list_new (ENVOYER_MODELS_TYPE_FOLDER, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);

    for(uint i = 0 ; i < folders->count() ; i++) {
        mailcore::IMAPFolder* folder = (mailcore::IMAPFolder*) folders->objectAtIndex(i);
        
        if ((folder->flags() & mailcore::IMAPFolderFlagNoSelect) != 0) {
            continue;
        }
        
        EnvoyerFolderStruct folder_struct;
        
        mailcore::IMAPFolderStatus* status = session->folderStatus(folder->path(), &error);
        folder_struct.unseen_count = status->unseenCount();
        folder_struct.message_count = status->messageCount();
        folder_struct.recent_count = status->recentCount();
        folder_struct.uid_next = status->uidNext();
        folder_struct.uid_validity = status->uidValidity();
        folder_struct.highest_mod_seq = status->highestModSeqValue();
        
        EnvoyerModelsFolder* folder_model = envoyer_models_folder_new (folder->path()->UTF8Characters(), folder->flags(), &folder_struct);

        gee_abstract_collection_add ((GeeAbstractCollection*) list, folder_model);
    }
    
    return list;
}
