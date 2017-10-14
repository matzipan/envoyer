/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#include <MailCore/MCIMAPAsyncSession.h>
#include <MailCore/MCOperationCallback.h>
#include <MailCore/MCIMAPOperationCallback.h>
#include <MailCore/MCIMAPMessageRenderingOperation.h>
#include <glib.h>
#include "envoyer.h"

class MailCoreInterfaceImapHTMLRenderingCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceImapHTMLRenderingCallback (GTask* task) {
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

extern "C" void mail_core_interface_imap_get_html_for_message (mailcore::IMAPAsyncSession* session, gchar* folder_path, EnvoyerModelsMessage* envoyer_message, GAsyncReadyCallback callback, void* user_data) {
    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto html_rendering_operation = session->htmlRenderingOperation ((mailcore::IMAPMessage *) envoyer_models_message_get_mailcore_message (envoyer_message), new mailcore::String (folder_path));

    auto session_callback = new MailCoreInterfaceImapHTMLRenderingCallback(task);
    html_rendering_operation->setImapCallback(session_callback);
    ((mailcore::Operation *) html_rendering_operation)->setCallback (session_callback);

    html_rendering_operation->start();
}

extern "C" const gchar* mail_core_interface_imap_get_html_for_message_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (const gchar*) g_task_propagate_pointer (task, NULL);
}
