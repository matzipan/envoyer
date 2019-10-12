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
#include <MailCore/MCIMAPFolder.h>
#include <MailCore/MCIMAPFolderStatus.h>
#include <MailCore/MCOperationCallback.h>
#include <MailCore/MCIMAPOperationCallback.h>
#include <MailCore/MCIMAPFetchFoldersOperation.h>
#include <MailCore/MCIMAPFolderStatusOperation.h>
#include <glib.h>
#include <gee.h>
#include <map>
#include "envoyer.h"
#include "imap.h"


class MailCoreInterfaceFetchFoldersCallbackCentralizer {
public:
    MailCoreInterfaceFetchFoldersCallbackCentralizer (GTask* task, mailcore::Array* folders) {
            this->task = task;
            this->folders = folders;
    }

    void increment_issued_count() {
        issued_count++;
    }

    void status_ready (mailcore::IMAPFolderStatusOperation* op) {
        statuses[std::string(op->folder()->UTF8Characters())] = op->status();

        ready_count++;
        if (ready_count == issued_count) {
            centralization_finished();
        }
    }

    void centralization_finished() {
        auto list = gee_linked_list_new (ENVOYER_MODELS_TYPE_FOLDER, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL, NULL, NULL);

        for(uint i = 0 ; i < folders->count () ; i++) {
            auto folder = (mailcore::IMAPFolder*) folders->objectAtIndex (i);

            if ((folder->flags () & mailcore::IMAPFolderFlagNoSelect) != 0) {
                continue;
            }

            EnvoyerFolderStruct folder_struct;

            auto status = statuses[std::string(folder->path()->UTF8Characters())];
            folder_struct.unseen_count = status->unseenCount ();
            folder_struct.message_count = status->messageCount ();
            folder_struct.recent_count = status->recentCount ();
            folder_struct.uid_next = status->uidNext ();
            folder_struct.uid_validity = status->uidValidity ();
            folder_struct.highest_modification_sequence = status->highestModSeqValue ();

            auto folder_model = envoyer_models_folder_new (folder->path ()->UTF8Characters (), folder->flags (), &folder_struct);

            gee_abstract_collection_add ((GeeAbstractCollection*) list, folder_model);
        }
        folders->release();

        g_task_return_pointer (task, list, g_object_unref);

        g_object_unref (task);
        delete this;
    }

private:
    GTask* task;
    mailcore::Array*  /* mailcore::Folder */ folders;
    int ready_count = 0;
    int issued_count = 0;
    std::map<std::string, mailcore::IMAPFolderStatus*> statuses;
};

class MailCoreInterfaceIMAPFoldersStatusCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceIMAPFoldersStatusCallback (MailCoreInterfaceFetchFoldersCallbackCentralizer* centralizer) {
            this->centralizer = centralizer;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        centralizer->status_ready((mailcore::IMAPFolderStatusOperation*) op);

        delete this;
    }
private:
    MailCoreInterfaceFetchFoldersCallbackCentralizer* centralizer;
};

#include <iostream>

class MailCoreInterfaceImapFetchFoldersCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceImapFetchFoldersCallback (GTask* task) {
            this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        auto folders = ((mailcore::IMAPFetchFoldersOperation *) op)->folders ();

        auto centralizer = new MailCoreInterfaceFetchFoldersCallbackCentralizer (task, folders);

        for(uint i = 0 ; i < folders->count () ; i++) {
            auto folder = (mailcore::IMAPFolder*) folders->objectAtIndex (i);

            if ((folder->flags () & mailcore::IMAPFolderFlagNoSelect) != 0) {
                continue;
            }

            /*
            The RFC says:

            Because the STATUS command is not guaranteed to be fast
            in its results, clients SHOULD NOT expect to be able to
            issue many consecutive STATUS commands and obtain
            reasonable performance.

            @TODO don't use folder status
            */

            auto folderStatusOperation = ((mailcore::IMAPOperation*) op)->mainSession()->folderStatusOperation(folder->path());

            auto folderStatusCallback = new MailCoreInterfaceIMAPFoldersStatusCallback (centralizer);

            ((mailcore::Operation *) folderStatusOperation)->setCallback(folderStatusCallback);

            centralizer->increment_issued_count();

            folderStatusOperation->start();
        }

        delete this;
    }

private:
    GTask* task;
};

extern "C" void mail_core_interface_imap_fetch_folders (void* voidSession, GAsyncReadyCallback callback, void* user_data) {
    auto session = (mailcore::IMAPAsyncSession*) voidSession;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto fetch_operation = session->fetchAllFoldersOperation();

    auto session_callback = new MailCoreInterfaceImapFetchFoldersCallback(task);
    fetch_operation->setImapCallback(session_callback);
    ((mailcore::Operation *) fetch_operation)->setCallback (session_callback);

    fetch_operation->start();
}

extern "C" GeeLinkedList* mail_core_interface_imap_fetch_folders_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (GeeLinkedList*) g_task_propagate_pointer (task, NULL);
}
