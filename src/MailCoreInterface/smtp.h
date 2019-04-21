/*
 * Copyright 2019 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#ifndef ENVOYER_MAILCOREINTERFACE_SMTP_H

#define ENVOYER_MAILCOREINTERFACE_SMTP_H

#include <gee.h>
#include <glib.h>

#ifdef __cplusplus
extern "C" {
#endif
void* mail_core_interface_smtp_connect (gchar* username, gchar* access_token);
void* mail_core_interface_smtp_update_access_token (void* session, gchar* access_token);
void mail_core_interface_smtp_send_message (void* session, void* message, GAsyncReadyCallback callback, void* user_data);
void mail_core_interface_smtp_send_message_finish (GTask *task);
#ifdef __cplusplus
}
#endif

#endif
