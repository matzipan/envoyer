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

using Envoyer.Globals.Application;
using Envoyer.Services;

public class Envoyer.Models.Identity : GLib.Object {
    public void* imap_session { get; set; }
    public void* imap_idle_session { get; set; }
    public void* smtp_session { get; set; }
    public DateTime expires_at { get; construct set; }
    public string access_token { get; construct set; }
    public string refresh_token { get; construct set; }
    public string account_name { get; construct set; }
    public Address address { get; construct set; }
    public signal void initialized ();
    private bool sessions_started = false;

    public Identity (string username, string access_token, string refresh_token, DateTime expires_at, string full_name, string account_name) {
        Object (account_name: account_name,
                access_token: access_token,
                refresh_token: refresh_token,
                expires_at: expires_at,
                address: new Address (full_name, username)
        );
    }

    public async void start_sessions (bool is_initialization) {
        if (sessions_started) {
            return;
        } else {
            sessions_started = true;
        }

        refresh_token_if_expired ();

        imap_session = MailCoreInterface.Imap.connect (address.email, access_token); //@TODO username is the same as email ony for Gmail, others might not work
        smtp_session = MailCoreInterface.Smtp.connect (address.email, access_token); //@TODO username is the same as email ony for Gmail, others might not work
        imap_idle_session = MailCoreInterface.Imap.connect (address.email, access_token); //@TODO username is the same as email ony for Gmail, others might not work

        notify["access_token"].connect (() => {
            MailCoreInterface.Imap.update_access_token (imap_session, access_token);
            MailCoreInterface.Imap.update_access_token (imap_idle_session, access_token);
            MailCoreInterface.Smtp.update_access_token (smtp_session, access_token);
        });

        refresh_token_loop.begin ();

        if (is_initialization) {
            fetch_folders.begin ((obj, result) => {
                fetch_folders.end (result);
                /*folder_list_changed ();*/

                fetch_messages.begin (get_folder_with_label ("INBOX"), 1, uint64.MAX, (obj, res) => {
                    fetch_messages.end (res);

                    idle_loop.begin ();

                    initialized ();
                });
            });
        } else {
            fetch_folders.begin ((obj, result) => {
                fetch_folders.end (result);
                /*folder_list_changed ();*/
            });

            idle_loop.begin ();
        }
        //@TODO status changes from the other folders
    }

    private string to_string () {
        return address.email;
    }

    // @TODO check if capability exists
    private async void idle_loop () {
        var index_folder = get_folder_with_label ("INBOX");

        while (true) {
            var highest_uid = index_folder.highest_uid;

            debug ("Idle loop: listening (highest uid %u)", highest_uid);
            yield MailCoreInterface.Imap.idle_listener (imap_idle_session, index_folder.name, highest_uid);

            debug ("Idle loop: idle stopped, fetching messages");
            var messages = yield fetch_messages (index_folder, highest_uid + 1, uint64.MAX);

            debug ("Idle loop: found %u messages, fetching updates", messages.size);
            yield fetch_message_updates (index_folder, 1, highest_uid); //@TODO use mod seq number to reduce the number of updates fetched

            // @TODO improve this
            // @TODO implement https://gist.github.com/matzipan/d0199db1706426a8f4436d707b3288fd
            foreach (var new_message in messages) {
                //string body = EmailUtil.strip_subject_prefixes(email);

                //@TODO strip/down in Address not here
                string md5 = GLib.Checksum.compute_for_string(ChecksumType.MD5, new_message.from.email.strip().down());

                var url = "https://secure.gravatar.com/avatar/%s?d=404&s=%d".printf(md5, 80);

                var avatar_file = File.new_for_uri (url);
                GLib.Icon icon = new ThemedIcon("internet-mail");
                try {
                    FileIOStream iostream;
                    var file = File.new_tmp("envoyer-contact-XXXXXX.png", out iostream);
                    iostream.close();
                    avatar_file.copy(file, GLib.FileCopyFlags.OVERWRITE);
                    icon = new FileIcon(file);
                } catch (Error e) {
                    debug ("Did not find avatar for %s".printf(new_message.from.email));
                }

                var notification = new GLib.Notification (new_message.from.email);
                notification.set_body (new_message.subject);
                notification.set_icon (icon);

                application.withdraw_notification ("message.new"); // @TODO this appears to not work in elementary?
                application.send_notification ("message.new", notification);
            }
        }
    }

    public async void nap (uint interval) {
        GLib.Timeout.add_seconds (interval, () => {
            nap.callback ();
            return false;
        }, GLib.Priority.DEFAULT);
        yield;
    }

    private async void refresh_token_loop () {
        while (true) {
            // Seconds to spare for refresh represents how much time before the expiry we refresh the access token
            var seconds_to_spare_for_refresh = 60;
            var seconds_until_refresh = (uint) (expires_at.to_unix () - (new DateTime.now_utc ()).to_unix ()) - seconds_to_spare_for_refresh;

            debug ("Refresh access token for identity %s scheduled in %u seconds", to_string (), seconds_until_refresh);

            //@TODO what happens if the internet is down when refresh is attempted and then when the imap/smtp sessions come back the token is still expired
            yield nap (seconds_until_refresh);

            do_token_refresh ();
        }
    }

    private void refresh_token_if_expired () {
        if (expires_at.compare (new DateTime.now_utc ()) > 0) {
            debug ("Access token is still valid for identity %s, not refreshing", to_string ());
            return;
        }

        do_token_refresh ();
    }

    private void do_token_refresh () {
        var session = new Soup.Session ();

        var msg = new Soup.Message ("POST", "https://www.googleapis.com/oauth2/v4/token");
        var encoded_data = Soup.Form.encode ("refresh_token",   refresh_token,
                                             "client_id",       "577724563203-55upnrbic0a2ft8qr809for8ns74jmqj.apps.googleusercontent.com",
                                             "client_secret",   "N_GoSZys__JPgKXrh_jIUuOh",
                                             "grant_type",      "refresh_token");

        msg.set_request ("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, encoded_data.data);
        session.send_message(msg);

        var response_object = Json.from_string ((string) msg.response_body.data).get_object ();

        access_token = response_object.get_string_member ("access_token");
        expires_at = (new DateTime.now_utc ()).add_seconds (response_object.get_int_member ("expires_in"));

        database.update_identity_access_token_and_expiry (this, access_token, expires_at);

        debug ("Updated access token and expiry date");
    }

    public Gee.Collection <Folder> get_folders () {
        var folders = database.get_folders_for_identity (account_name);

        foreach (var item in folders) {
            item.identity = this;
        }

        return folders;
    }

    public Folder? get_folder_with_label (string label) {
        foreach (var folder in get_folders ()) {
            if (folder.name == label) {
                return folder;
            }
        }

        return null;
    }

    public async Gee.Collection <Folder> fetch_folders () {
        var folders = yield MailCoreInterface.Imap.fetch_folders (imap_session);

        foreach (var item in folders) {
            item.identity = this;
        }

        database.set_folders_for_identity (folders, account_name);

        return folders;
    }

    public Gee.Collection <ConversationThread> get_threads (Folder folder) {
        return database.get_threads_for_folder (folder);
    }

    public async Gee.Collection <Message> fetch_messages (Folder folder, uint64 start_uid_value, uint64 end_uid_value) {
        var messages = yield MailCoreInterface.Imap.fetch_messages (imap_session, folder.name, start_uid_value, end_uid_value, false);

        foreach (var item in messages) {
            item.folder = folder;
            item.html_content = yield get_html_for_message (item);
            item.plain_text_content = yield get_plain_text_for_message (item);

            //@TODO implement lazy attachment downloading
            foreach (var attachment in item.non_inline_attachments) {
                if (attachment.part_id.size () != 0) {
                    debug ("Found non-inline attachment with part id %s, fetching now", attachment.part_id);
                    attachment.data = yield MailCoreInterface.Imap.fetch_data_for_message_part (
                        imap_session,
                        folder.name,
                        item.uid,
                        attachment.part_id,
                        attachment.encoding
                    );
                }
            }
        }

        database.set_messages_for_folder (messages, folder);

        return messages;
    }

    public async Gee.Collection <Message> fetch_message_updates (Folder folder, uint64 start_uid_value, uint64 end_uid_value) {
        var messages = yield MailCoreInterface.Imap.fetch_messages (imap_session, folder.name, start_uid_value, end_uid_value, true);

        foreach (var item in messages) {
            item.folder = folder;
        }

        database.update_messages_for_folder (messages, folder);

        return messages;
    }

    public async string get_html_for_message (Message message) {
        return yield MailCoreInterface.Imap.get_html_for_message (imap_session, message.folder.name, message);
    }
    
    public async string get_plain_text_for_message (Message message) {
        return yield MailCoreInterface.Imap.get_plain_text_for_message (imap_session, message.folder.name, message);
    }

    public void send_message (Message message) {
        message.from = address;

        MailCoreInterface.Smtp.send_message (smtp_session, message);
    }
}
