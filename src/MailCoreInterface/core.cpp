/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
#include <MailCore/MCIMAPSession.h>
#include <MailCore/MCIMAPFolder.h>
#include <MailCore/MCIMAPFolderStatus.h>
#include <MailCore/MCMessageHeader.h>
#include <MailCore/MCAddress.h>
#include <glib.h>
#include <gee.h>
#include "envoyer.h"
 
extern "C" void* mail_core_interface_connect (gchar* username, gchar* password) {
    auto session = new mailcore::IMAPSession();

    session->setUsername (new mailcore::String (username));
    session->setPassword (new mailcore::String (password));
    session->setHostname (new mailcore::String ("imap.gmail.com"));
    session->setPort (993);
    session->setConnectionType (mailcore::ConnectionTypeTLS);
    
    
    //@TODO also close the connection?
    return session;
}

extern "C" GeeLinkedList* mail_core_interface_fetch_folders (mailcore::IMAPSession* session) {
    mailcore::ErrorCode error; //@TODO check error

    auto folders = session->fetchAllFolders (&error);

    auto list = gee_linked_list_new (ENVOYER_MODELS_TYPE_FOLDER, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);

    for(uint i = 0 ; i < folders->count () ; i++) {
        auto folder = (mailcore::IMAPFolder*) folders->objectAtIndex (i);
        
        if ((folder->flags () & mailcore::IMAPFolderFlagNoSelect) != 0) {
            continue;
        }
        
        EnvoyerFolderStruct folder_struct;
        
        auto status = session->folderStatus (folder->path(), &error);
        folder_struct.unseen_count = status->unseenCount ();
        folder_struct.message_count = status->messageCount ();
        folder_struct.recent_count = status->recentCount ();
        folder_struct.uid_next = status->uidNext ();
        folder_struct.uid_validity = status->uidValidity ();
        folder_struct.highest_mod_seq = status->highestModSeqValue ();
        
        auto folder_model = envoyer_models_folder_new (folder->path ()->UTF8Characters (), folder->flags (), &folder_struct);

        gee_abstract_collection_add ((GeeAbstractCollection*) list, folder_model);
    }

    delete folders;
    
    return list;
}

EnvoyerModelsAddress* get_as_envoyer_address (mailcore::Address* address) {
    return envoyer_models_address_new (
            address->displayName () == NULL ? "" : address->displayName ()->UTF8Characters (),
            address->mailbox ()->UTF8Characters ()
        );
}

GeeLinkedList* get_as_list_of_envoyer_addresses (mailcore::Array* addresses) {
    GeeLinkedList* list = gee_linked_list_new (ENVOYER_MODELS_TYPE_ADDRESS, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);

    if(addresses != NULL) {
        for(uint i = 0 ; i < addresses->count () ; i++) {
            mailcore::Address* address = (mailcore::Address*) addresses->objectAtIndex (i);

            gee_abstract_collection_add ((GeeAbstractCollection*) list, get_as_envoyer_address (address));
        }
    }
    
    return list;
}

extern "C" GeeLinkedList* mail_core_interface_fetch_messages (mailcore::IMAPSession* session, gchar* folder_path) {
    mailcore::ErrorCode error; //@TODO check error
        
    auto uidRange = mailcore::IndexSet::indexSetWithRange (mailcore::RangeMake (1, UINT64_MAX));
    auto kind = mailcore::IMAPMessagesRequestKindHeaders |
        mailcore::IMAPMessagesRequestKindFlags |
        mailcore::IMAPMessagesRequestKindStructure |
        mailcore::IMAPMessagesRequestKindGmailLabels |
        mailcore::IMAPMessagesRequestKindGmailThreadID |
        mailcore::IMAPMessagesRequestKindGmailMessageID;
        
    auto messages = session->fetchMessagesByUID (new mailcore::String (folder_path), (mailcore::IMAPMessagesRequestKind) kind, uidRange, NULL, &error);

    auto list = gee_linked_list_new (ENVOYER_MODELS_TYPE_MESSAGE, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);        

    for(uint i = 0 ; i < messages->count () ; i++) {
        auto message = (mailcore::IMAPMessage*) messages->objectAtIndex (i);

        auto from_address = get_as_envoyer_address (message->header ()->from ());
        auto sender_address = get_as_envoyer_address (message->header ()->sender ());
        
        auto to_addresses = get_as_list_of_envoyer_addresses (message->header ()->to ());
        auto cc_addresses = get_as_list_of_envoyer_addresses (message->header ()->cc ());
        auto bcc_addresses = get_as_list_of_envoyer_addresses (message->header ()->bcc ());

        auto references_list = gee_linked_list_new (G_TYPE_STRING, (GBoxedCopyFunc) g_strdup, g_free, NULL, NULL, NULL);

        auto references = message-> header()->references ();

        if (references != NULL) {
            for(uint j = 0 ; j < references->count (); j++) {
                mailcore::String* reference = (mailcore::String*) references->objectAtIndex (j);
                
                gee_abstract_collection_add ((GeeAbstractCollection*) references_list, reference->UTF8Characters ());
            }
        }

        message->retain();
        
        EnvoyerModelsMessage* message_model = envoyer_models_message_new (
            message,
            from_address,
            sender_address,
            (GeeCollection*) to_addresses,
            (GeeCollection*) cc_addresses,
            (GeeCollection*) bcc_addresses,
            message->header ()->subject ()->UTF8Characters (),
            message->header ()->receivedDate (),
            (GeeCollection*) references_list,
            message->header ()->messageID ()->UTF8Characters ()
        );

        gee_abstract_collection_add ((GeeAbstractCollection*) list, message_model);
    }

    delete messages;
    //@TODO also release when Envoyer.Models.Message is deleted.

    return list;
}

extern "C" const gchar* mail_core_interface_get_html_for_message (mailcore::IMAPSession* session, gchar* folder_path, EnvoyerModelsMessage* envoyer_message) {
    mailcore::ErrorCode error; //@TODO check error

    return session->htmlRendering ((mailcore::IMAPMessage *) envoyer_models_message_get_mailcore_message (envoyer_message), new mailcore::String (folder_path), &error)->UTF8Characters();
}
