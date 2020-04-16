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

extern "C" void mail_core_interface_imap_idle_listener (void* voidSession, gchar* folder_path, guint64 last_known_uid, GAsyncReadyCallback callback, void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto idle_operation = session->idleOperation (new mailcore::String(folder_path), last_known_uid);

    auto idle_callback = new MailCoreInterfaceIMAPIdleListenerCallback(task);
    idle_operation->setImapCallback(idle_callback);
    ((mailcore::Operation *) idle_operation)->setCallback (idle_callback);

    idle_operation->start();
}

extern "C" gboolean mail_core_interface_imap_idle_listener_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return static_cast <gboolean> (g_task_propagate_boolean (task, NULL));
}
