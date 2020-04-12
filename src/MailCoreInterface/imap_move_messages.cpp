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
#include <MailCore/MCIMAPMoveMessagesOperation.h>
#include <MailCore/MCIndexSet.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"
#include <errno.h>


class MailCoreInterfaceMoveMessagesCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceMoveMessagesCallback (GTask* task) {
            this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        g_task_return_boolean (task, true);

        g_object_unref (task);
        delete this;
    }
private:
    GTask* task;
};

extern "C" void mail_core_interface_imap_move_messages (void* voidSession, gchar* source_folder_path, GeeList* message_uids, gchar* destination_folder_path, GAsyncReadyCallback callback, void* user_data) {
    auto session = static_cast <mailcore::IMAPAsyncSession*> (voidSession);

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto index_set = new mailcore::IndexSet ();

    for (uint i = 0; i < gee_abstract_collection_get_size (reinterpret_cast <GeeAbstractCollection*> (message_uids)); i++) {
        index_set->addIndex (*static_cast <uint64_t*> (gee_abstract_list_get (reinterpret_cast <GeeAbstractList*> (message_uids), i)));
    }

    auto move_messages_operation = session->moveMessagesOperation (new mailcore::String (source_folder_path), index_set, new mailcore::String (destination_folder_path));

    auto move_messages_callback = new MailCoreInterfaceMoveMessagesCallback(task);
    move_messages_operation->setImapCallback (move_messages_callback);
    
    static_cast <mailcore::Operation *> (move_messages_operation)->setCallback (move_messages_callback);

    move_messages_operation->start();
}

extern "C" const gboolean mail_core_interface_imap_move_messages_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return static_cast <const gboolean> (g_task_propagate_boolean (task, NULL));
}
