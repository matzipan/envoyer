/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

 #include <MailCore/MCIMAPAsyncSession.h>
 #include <MailCore/MCOperationCallback.h>
 #include <MailCore/MCIMAPOperationCallback.h>
 #include <MailCore/MCIMAPIdleOperation.h>
 #include <glib.h>
 #include <gee.h>
 #include "envoyer.h"
 #include "imap.h"


 class MailCoreInterfaceIMAPIdleListenerCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
 public:
    MailCoreInterfaceIMAPIdleListenerCallback (GTask* task) {
        this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        g_task_return_boolean (task, true);

        g_object_unref (task);
        delete this;
    }

private:
     GTask* task;
};

 extern "C" void mail_core_interface_imap_idle_listener (void* voidSession, gchar* folder_path, guint64 last_known_id, GAsyncReadyCallback callback, void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto idle_operation = session->idleOperation (new mailcore::String(folder_path), last_known_id);

    auto idle_callback = new MailCoreInterfaceIMAPIdleListenerCallback(task);
    idle_operation->setImapCallback(idle_callback);
    ((mailcore::Operation *) idle_operation)->setCallback (idle_callback);

    idle_operation->start();
 }

 extern "C" void mail_core_interface_imap_idle_listener_finish (GTask *task) {
     g_assert(g_task_is_valid (task, NULL));

     return;
 }
