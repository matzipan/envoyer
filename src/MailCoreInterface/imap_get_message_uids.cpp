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
#include <MailCore/MCIMAPSearchOperation.h>
#include <MailCore/MCIndexSet.h>
#include <glib.h>
#include <gee.h>
#include "envoyer.h"
#include "imap.h"


class MailCoreInterfaceGetMessageUidsCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceGetMessageUidsCallback (GTask* task) {
            this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error
        
        auto uids_index_set = static_cast <mailcore::IMAPSearchOperation *> (op)->uids ();

        auto ranges_list = gee_linked_list_new (ENVOYER_UTIL_TYPE_RANGE, static_cast <GBoxedCopyFunc> (envoyer_util_range_ref), envoyer_util_range_unref, NULL, NULL, NULL);

        for (unsigned int i = 0; i < uids_index_set->rangesCount (); i++) {
            auto range = uids_index_set->allRanges()[i];

            auto envoyer_range = envoyer_util_range_new (range.location, range.length);

            gee_abstract_collection_add (reinterpret_cast <GeeAbstractCollection*> (ranges_list), envoyer_range);
        }

        g_task_return_pointer (task, ranges_list, g_object_unref);

        g_object_unref (task);
        delete this;
    }
private:
    GTask* task;
};

extern "C" void mail_core_interface_imap_get_message_uids_for_folder (void* voidSession, gchar* folder_path, GAsyncReadyCallback callback, void* user_data) {
    auto session = static_cast <mailcore::IMAPAsyncSession*> (voidSession);

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto search_operation = session->searchOperation (new mailcore::String (folder_path), mailcore::IMAPSearchKind::IMAPSearchKindAll, nullptr);

    auto search_callback = new MailCoreInterfaceGetMessageUidsCallback(task);
    search_operation->setImapCallback (search_callback);
    
    static_cast <mailcore::Operation *> (search_operation)->setCallback (search_callback);

    search_operation->start();
}

extern "C" GeeLinkedList* mail_core_interface_imap_get_message_uids_for_folder_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return reinterpret_cast <GeeLinkedList*> (g_task_propagate_pointer (task, NULL));
}
