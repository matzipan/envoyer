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
#include <MailCore/MCOperationCallback.h>
#include <MailCore/MCIMAPOperationCallback.h>
#include <MailCore/MCIMAPFetchMessagesOperation.h>
#include <MailCore/MCMessageHeader.h>
#include <MailCore/MCIMAPMessage.h>
#include <MailCore/MCAddress.h>
#include <glib.h>
#include <gee.h>
#include "envoyer.h"
#include "imap.h"


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

class MailCoreInterfaceIMAPFetchMessagesByUIDCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceIMAPFetchMessagesByUIDCallback (GTask* task, gboolean flags_only) {
            this->task = task;
            this->flags_only = flags_only;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        auto messages = ((mailcore::IMAPFetchMessagesOperation *) op)->messages();
        auto vanished_messages = ((mailcore::IMAPFetchMessagesOperation *) op)->vanishedMessages(); //@TODO

        auto list = gee_linked_list_new (ENVOYER_MODELS_TYPE_MESSAGE, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);

        for(uint i = 0 ; i < messages->count () ; i++) {
            auto message = (mailcore::IMAPMessage*) messages->objectAtIndex (i);

            EnvoyerModelsMessage* message_model;

            if (flags_only) {
                message_model = envoyer_models_message_new_for_flag_updating (
                    message,
                    message->header ()->messageID ()->UTF8Characters (),
                    message->uid (),
                    message->sequenceNumber (),
                    (message->flags () & mailcore::MessageFlagSeen) != 0,
                    (message->flags () & mailcore::MessageFlagFlagged) != 0,
                    (message->flags () & mailcore::MessageFlagDeleted) != 0,
                    (message->flags () & mailcore::MessageFlagDraft) != 0
                );
            } else {
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

                auto in_reply_to_list = gee_linked_list_new (G_TYPE_STRING, (GBoxedCopyFunc) g_strdup, g_free, NULL, NULL, NULL);

                auto in_reply_to = message->header ()->inReplyTo ();

                if (in_reply_to != NULL) {
                    for(uint j = 0 ; j < in_reply_to->count (); j++) {
                        mailcore::String* in_reply_to_item = (mailcore::String*) in_reply_to->objectAtIndex (j);

                        gee_abstract_collection_add ((GeeAbstractCollection*) in_reply_to_list, in_reply_to_item->UTF8Characters ());
                    }
                }

                message->retain(); //@TODO this should be called from Envoyer.Models.Message constructor

                auto subject = "";

                if(message->header ()->subject ()  != 0) {
                    subject = message->header ()->subject ()->UTF8Characters ();
                }

                message_model = envoyer_models_message_new (
                    message,
                    from_address,
                    sender_address,
                    (GeeCollection*) to_addresses,
                    (GeeCollection*) cc_addresses,
                    (GeeCollection*) bcc_addresses,
                    subject,
                    message->header ()->receivedDate (),
                    (GeeList*) references_list,
                    (GeeList*) in_reply_to_list,
                    message->header ()->messageID ()->UTF8Characters (),
                    message->uid (),
                    message->sequenceNumber (),
                    (message->flags () & mailcore::MessageFlagSeen) != 0,
                    (message->flags () & mailcore::MessageFlagFlagged) != 0,
                    (message->flags () & mailcore::MessageFlagDeleted) != 0,
                    (message->flags () & mailcore::MessageFlagDraft) != 0
                );

            }

            gee_abstract_collection_add ((GeeAbstractCollection*) list, message_model);
        }

        messages->release();
        //@TODO also release when Envoyer.Models.Message is deleted.

        g_task_return_pointer (task, list, g_object_unref);

        g_object_unref (task);
        delete this;
    }

private:
    GTask* task;
    gboolean flags_only;
};

extern "C" void mail_core_interface_imap_fetch_messages (void* voidSession,
                                                        gchar* folder_path,
                                                        guint64 start_uid_value,
                                                        guint64 end_uid_value,
                                                        gboolean flags_only,
                                                        GAsyncReadyCallback callback,
                                                        void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto uidRange = mailcore::IndexSet::indexSetWithRange (mailcore::RangeMake (start_uid_value, end_uid_value - start_uid_value));

    int kind;
    if (flags_only) {
        kind = mailcore::IMAPMessagesRequestKindHeaders |
            mailcore::IMAPMessagesRequestKindFlags;
    } else {
        kind = mailcore::IMAPMessagesRequestKindHeaders |
            mailcore::IMAPMessagesRequestKindFlags |
            mailcore::IMAPMessagesRequestKindStructure |
            mailcore::IMAPMessagesRequestKindGmailLabels |
            mailcore::IMAPMessagesRequestKindGmailThreadID |
            mailcore::IMAPMessagesRequestKindGmailMessageID;
    }

    auto fetch_messages_operation = session->fetchMessagesByUIDOperation(new mailcore::String (folder_path), (mailcore::IMAPMessagesRequestKind) kind, uidRange);

    auto session_callback = new MailCoreInterfaceIMAPFetchMessagesByUIDCallback(task, flags_only);

    // fetch_messages_operation->setImapCallback(session_callback); @TODO for progress feedback
    ((mailcore::Operation *) fetch_messages_operation)->setCallback (session_callback);

    fetch_messages_operation->start();
}

extern "C" GeeLinkedList* mail_core_interface_imap_fetch_messages_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (GeeLinkedList*) g_task_propagate_pointer (task, NULL);
}
