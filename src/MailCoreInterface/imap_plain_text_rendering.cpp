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
#include <MailCore/MCIMAPMessageRenderingOperation.h>
#include <glib.h>
#include "envoyer.h"
#include "imap.h"


class MailCoreInterfaceIMAPPlainTextBodyRenderingCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceIMAPPlainTextBodyRenderingCallback (GTask* task) {
            this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        auto result = ((mailcore::IMAPMessageRenderingOperation *) op)->result();

        g_task_return_pointer (task, (gpointer) result->UTF8Characters(), g_object_unref);

        g_object_unref (task);
        delete this;
    }
private:
    GTask* task;
};

extern "C" void mail_core_interface_imap_get_plain_text_for_message (void* voidSession, gchar* folder_path, void* void_envoyer_message, GAsyncReadyCallback callback, void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;
    // If I'm including the envoyer header file, it complains about the redefinition of some things. So we're avoiding this and just keeping function header agnostic of the pointer's type
    auto envoyer_message = (EnvoyerModelsMessage*) void_envoyer_message;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto plain_text_body_rendering_operation = session->plainTextRenderingOperation ((mailcore::IMAPMessage *) envoyer_models_message_get_mailcore_message (envoyer_message), new mailcore::String (folder_path));

    auto rendering_callback = new MailCoreInterfaceIMAPPlainTextBodyRenderingCallback(task);
    plain_text_body_rendering_operation->setImapCallback(rendering_callback);
    ((mailcore::Operation *) plain_text_body_rendering_operation)->setCallback (rendering_callback);

    plain_text_body_rendering_operation->start();
}

extern "C" const gchar* mail_core_interface_imap_get_plain_text_for_message_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (const gchar*) g_task_propagate_pointer (task, NULL);
}