/*
 * Copyright (C) 2020  Andrei-Costin Zisu
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
#include <MailCore/MCIMAPFetchContentOperation.h>
#include <MailCore/MCIMAPOperation.h>
#include <MailCore/MCIMAPOperationCallback.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"

class MailCoreInterfaceIMAPFetchMessageAttachmentByUID : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceIMAPFetchMessageAttachmentByUID (GTask* task) {
        this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        auto data = ((mailcore::IMAPFetchContentOperation *) op)->data();

        GBytes* dataBytes = g_bytes_new (data->bytes(), data->length());
        
        g_task_return_pointer (task, dataBytes, g_object_unref);

        g_object_unref (task);
        delete this;
    }

private:
    GTask* task;
};


extern "C" void mail_core_interface_imap_fetch_data_for_message_part (void* voidSession, gchar* folder_path, guint64 uid, gchar* part_id, gint64 encoding, GAsyncReadyCallback callback, void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;
   
    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto fetch_content_operation = session->fetchMessageAttachmentByUIDOperation (
        new mailcore::String (folder_path),
        static_cast<uint32_t> (uid),
        new mailcore::String (part_id),
        static_cast<mailcore::Encoding> (encoding)
    );

    auto fetch_callback = new MailCoreInterfaceIMAPFetchMessageAttachmentByUID (task);

    fetch_content_operation->setImapCallback (fetch_callback);
    ((mailcore::Operation *) fetch_content_operation)->setCallback (fetch_callback);

    fetch_content_operation->start ();
}

extern "C" GBytes* mail_core_interface_imap_fetch_data_for_message_part_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (GBytes*) g_task_propagate_pointer (task, NULL);
}
