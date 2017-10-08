/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
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
#include "envoyer.h"
#include <map>


class MailCoreInterfaceFetchFoldersCallbackCentralizer {
public:
    MailCoreInterfaceFetchFoldersCallbackCentralizer (GTask* task, mailcore::Array* folders) {
            this->task = task;
            this->folders = folders;
    }

    void incrementIssuedCount() {
        issuedCount++;
    }

    void statusReady (mailcore::IMAPFolderStatusOperation* op) {
        statuses[std::string(op->folder()->UTF8Characters())] = op->status();

        readyCount++;
        if (readyCount == issuedCount) {
            centralizationFinished();
        }
    }

    void centralizationFinished() {
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
            folder_struct.highest_mod_seq = status->highestModSeqValue ();

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
    int readyCount = 0;
    int issuedCount = 0;
    std::map<std::string, mailcore::IMAPFolderStatus*> statuses;
};

class MailCoreInterfaceImapFoldersStatusCallback : public mailcore::OperationCallback, public mailcore::IMAPOperationCallback {
public:
    MailCoreInterfaceImapFoldersStatusCallback (MailCoreInterfaceFetchFoldersCallbackCentralizer* centralizer) {
            this->centralizer = centralizer;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check IMAPOperation::error

        centralizer->statusReady((mailcore::IMAPFolderStatusOperation*) op);

        delete this;
    }
private:
    MailCoreInterfaceFetchFoldersCallbackCentralizer* centralizer;
};

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

            auto folderStatusCallback = new MailCoreInterfaceImapFoldersStatusCallback (centralizer);

            ((mailcore::Operation *) folderStatusOperation)->setCallback(folderStatusCallback);

            centralizer->incrementIssuedCount();

            folderStatusOperation->start();
        }

        delete this;
    }

private:
    GTask* task;
};

extern "C" void mail_core_interface_imap_fetch_folders (mailcore::IMAPAsyncSession* session, GAsyncReadyCallback callback, void* user_data) {
    auto task = g_task_new (NULL, NULL, callback, user_data);

    auto fetchOperation = session->fetchAllFoldersOperation();

    auto session_callback = new MailCoreInterfaceImapFetchFoldersCallback(task);
    fetchOperation->setImapCallback(session_callback);
    ((mailcore::Operation *) fetchOperation)->setCallback (session_callback);

    fetchOperation->start();
}

extern "C" GeeLinkedList* mail_core_interface_imap_fetch_folders_finish (GTask *task) {
    g_return_val_if_fail (g_task_is_valid (task, NULL), NULL);

    return (GeeLinkedList*) g_task_propagate_pointer (task, NULL);
}
