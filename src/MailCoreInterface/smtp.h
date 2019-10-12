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
