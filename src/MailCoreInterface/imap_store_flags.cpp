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
#include <MailCore/MCIMAPStoreFlagsOperation.h>
#include <MailCore/MCIndexSet.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"


class MailCoreInterfaceStoreFlagsCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceStoreFlagsCallback (GTask* task) {
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

extern "C" void mail_core_interface_imap_store_flags_for_messages (void* voidSession, gchar* folder_path, GeeList* message_uids, GAsyncReadyCallback callback, void* user_data) {
    auto session = reinterpret_cast <mailcore::IMAPAsyncSession*> (voidSession);

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto index_set = new mailcore::IndexSet ();

    for (uint i = 0; i < gee_abstract_collection_get_size (reinterpret_cast <GeeAbstractCollection*> (message_uids)); i++) {
        index_set->addIndex (*static_cast <uint64_t*> (gee_abstract_list_get (reinterpret_cast <GeeAbstractList*> (message_uids), i)));
    }

    auto kind = mailcore::IMAPStoreFlagsRequestKind::IMAPStoreFlagsRequestKindSet;
    auto flags = mailcore::MessageFlag::MessageFlagSeen; //@TODO generalize this

    auto store_flags_operation = session->storeFlagsByUIDOperation (new mailcore::String (folder_path), index_set, kind, flags, nullptr);

    auto store_flags_callback = new MailCoreInterfaceStoreFlagsCallback(task);
    store_flags_operation->setImapCallback (store_flags_callback);
    ((mailcore::Operation *) store_flags_operation)->setCallback (store_flags_callback);

    store_flags_operation->start();
}

extern "C" gboolean mail_core_interface_imap_store_flags_for_message_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return static_cast <gboolean> (g_task_propagate_boolean (task, NULL));
}
