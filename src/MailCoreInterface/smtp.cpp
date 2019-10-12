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

#include <MailCore/MCSMTPAsyncSession.h>
#include <MailCore/MCOperationCallback.h>
#include <MailCore/MCSMTPOperationCallback.h>
#include <MailCore/MCSMTPOperation.h>
#include <MailCore/MCMessageBuilder.h>
#include <MailCore/MCMessageHeader.h>
#include <MailCore/MCAddress.h>
#include <glib.h>
#include <gee.h>
#include "envoyer.h"
#include "smtp.h"

extern "C" void* mail_core_interface_smtp_connect (gchar* username, gchar* access_token) {
    auto session = new mailcore::SMTPAsyncSession ();

    session->setUsername (new mailcore::String (username));
    session->setAuthType(mailcore::AuthTypeXOAuth2);
    session->setOAuth2Token(new mailcore::String (access_token));
    session->setHostname (new mailcore::String ("imap.gmail.com"));
    session->setPort (465);
    session->setConnectionType (mailcore::ConnectionTypeTLS);

    //@TODO also close the connection?
    return session;
}

extern "C" void* mail_core_interface_smtp_update_access_token (void* session, gchar* access_token) {
    auto smtp_async_session = (mailcore::SMTPAsyncSession*) session;

    smtp_async_session->setOAuth2Token (new mailcore::String (access_token));
}

mailcore::Array* /* mailcore::Address */ get_as_array_of_mailcore_addresses (GeeCollection * envoyer_addresses) {
    auto addresses_array = new mailcore::Array ();

    for (uint i = 0; i < gee_abstract_collection_get_size ((GeeAbstractCollection*) envoyer_addresses); i++) {
        auto item = (EnvoyerModelsAddress*) gee_abstract_list_get ((GeeAbstractList*) envoyer_addresses, i);

        addresses_array->addObject(
            mailcore::Address::addressWithDisplayName(
                new mailcore::String (envoyer_models_address_get_name (item)),
                new mailcore::String (envoyer_models_address_get_email (item))
            )
        );
    }

    return addresses_array;
}

class MailCoreInterfaceSMTPMessageSendCallback : public mailcore::OperationCallback, public mailcore::SMTPOperationCallback {
public:
    MailCoreInterfaceSMTPMessageSendCallback (GTask* task) {
            this->task = task;
    }

    virtual void operationFinished(mailcore::Operation * op) {
        //@TODO check SMTPOperation::error

        auto operation = ((mailcore::SMTPOperation *) op);

        g_task_return_pointer (task, NULL, g_object_unref);

        g_object_unref (task);
        delete this;
    }
private:
    GTask* task;
};

extern "C" void mail_core_interface_smtp_send_message (void* session, void* void_envoyer_message, GAsyncReadyCallback callback, void* user_data) {
    auto smtp_async_session = (mailcore::SMTPAsyncSession*) session;

    auto message = (EnvoyerModelsMessage*) void_envoyer_message;

    auto task = g_task_new (NULL, NULL, callback, user_data);

    //@TODO ref and unref message

    auto builder = new mailcore::MessageBuilder ();

    builder->header()->setFrom(
        mailcore::Address::addressWithDisplayName(
            new mailcore::String (envoyer_models_address_get_name (envoyer_models_message_get_from (message))),
            new mailcore::String (envoyer_models_address_get_email (envoyer_models_message_get_from (message)))
        )
    );

    builder->header()->setTo(get_as_array_of_mailcore_addresses (envoyer_models_message_get_to (message)));
    builder->header()->setCc(get_as_array_of_mailcore_addresses (envoyer_models_message_get_cc (message)));
    builder->header()->setBcc(get_as_array_of_mailcore_addresses (envoyer_models_message_get_bcc (message)));

    builder->header()->setSubject(new mailcore::String (envoyer_models_message_get_subject (message)));
    builder->setTextBody(new mailcore::String (envoyer_models_message_get_text (message)));

    // @TODO setHTMLBody();

    auto send_message_operation = smtp_async_session->sendMessageOperation(builder->data());

    auto send_callback = new MailCoreInterfaceSMTPMessageSendCallback(task);
    send_message_operation->setSmtpCallback(send_callback);
    //@TODO smtp operation callback
    //@TODO smtp progress callback
    ((mailcore::Operation *) send_message_operation)->setCallback (send_callback);

    send_message_operation->start();
}

extern "C" void mail_core_interface_smtp_send_message_finish (GTask *task) {
    return;
}
