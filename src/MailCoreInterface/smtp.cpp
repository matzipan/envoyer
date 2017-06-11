/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
#include <MailCore/MCSMTPSession.h>
#include <MailCore/MCMessageBuilder.h>
#include <MailCore/MCMessageHeader.h>
#include <MailCore/MCAddress.h>
#include <glib.h>
#include <gee.h>
#include "envoyer.h"

extern "C" void* mail_core_interface_smtp_connect (gchar* username, gchar* password) {
    auto session = new mailcore::SMTPSession ();

    session->setUsername (new mailcore::String (username));
    session->setPassword (new mailcore::String (password));
    session->setHostname (new mailcore::String ("imap.gmail.com"));
    session->setPort (465);
    session->setConnectionType (mailcore::ConnectionTypeTLS);
        
    //@TODO also close the connection?
    return session;
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

extern "C" void mail_core_interface_smtp_send_message (mailcore::SMTPSession* session, EnvoyerModelsMessage* message) {
    mailcore::ErrorCode error; //@TODO check error
    
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

    session->sendMessage(builder->data(), NULL, &error);
}
