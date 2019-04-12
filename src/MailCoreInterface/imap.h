/*
 * Copyright 2018 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

#ifndef ENVOYER_MAILCOREINTERFACE_IMAP_H

#define ENVOYER_MAILCOREINTERFACE_IMAP_H

#include <gee.h>
#include <glib.h>

#ifdef __cplusplus
extern "C" {
#endif
void* mail_core_interface_imap_connect (gchar* username, gchar* access_token);
void mail_core_interface_imap_fetch_folders (void* session, GAsyncReadyCallback callback, void* user_data);
GeeLinkedList* mail_core_interface_imap_fetch_folders_finish (GTask *task);
void mail_core_interface_imap_fetch_messages (void* session, gchar* folder_path, guint64 start_uid_value, guint64 end_uid_value, gboolean flags_only, GAsyncReadyCallback callback, void* user_data);
GeeLinkedList* mail_core_interface_imap_fetch_messages_finish (GTask *task);
void mail_core_interface_imap_get_html_for_message (void* session, gchar* folder_path, void* envoyer_message, GAsyncReadyCallback callback, void* user_data);
void mail_core_interface_imap_get_html_for_message (void* session, gchar* folder_path, void* envoyer_message, GAsyncReadyCallback callback, void* user_data);
const gchar* mail_core_interface_imap_get_html_for_message_finish (GTask *task);
void mail_core_interface_imap_idle_listener (void* session, gchar* folder_path, guint64 last_known_id, GAsyncReadyCallback callback, void* user_data);
void mail_core_interface_imap_idle_listener_finish (GTask *task);
#ifdef __cplusplus
}
#endif

#endif
