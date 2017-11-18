/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Globals.Application;
using Envoyer.Services;

public class Envoyer.Models.Identity : GLib.Object {
    public void* imap_session { get; construct set; }
    public void* imap_idle_session { get; construct set; }
    public void* smtp_session { get; construct set; }
    public string account_name { get; construct set; }
    public Address address { get; construct set; }

    public async Identity (string username, string password, string full_name, string account_name) {
        Object (account_name: account_name,
                imap_session: MailCoreInterface.Imap.connect (username, password),
                smtp_session: MailCoreInterface.Smtp.connect (username, password),
                imap_idle_session: MailCoreInterface.Imap.connect (username, password),
                address: new Address (full_name, username) //@TODO username is the same as email ony for Gmail, others might not work
        );
    }

    construct {
        fetch_folders.begin ((obj, result) => {
            fetch_folders.end (result);
            /*folder_list_changed ();*/
        });

        //@TODO fetch once when initalized
        /*identity.fetch_threads.begin (this, (obj, res) => {
            identity.fetch_threads.end (res);
        });*/

        idle_loop.begin ();

        //@TODO status changes from the other folders
    }

    // @TODO check if capability exists
    public async void idle_loop () {
        var index_folder = get_folder_with_label ("INBOX");

        while (true) {
            yield MailCoreInterface.Imap.idle_listener (imap_idle_session, index_folder.name, index_folder.highest_uid); //@TODO this fails when there are no emails in db

            var messages = yield fetch_messages (index_folder);

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
                    var file = File.new_tmp("geary-contact-XXXXXX.png", out iostream);
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

            yield fetch_message_updates (index_folder); //@TODO use mod seq number to reduce the number of updates fetched
            application.database_updated ("INBOX"); //@TODO there needs to be a centralized factory of objects, conversation threads so that we can nicely handle updates and signals
        }
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

    public async Gee.Collection <Message> fetch_messages (Folder folder) {
        var messages = yield MailCoreInterface.Imap.fetch_messages (imap_session, folder.name, folder.highest_uid + 1, uint.MAX, false);

        foreach (var item in messages) {
            item.folder = folder;
        }

        database.set_messages_for_folder (messages, folder);

        return messages;
    }

    public async Gee.Collection <Message> fetch_message_updates (Folder folder) {
        var messages = yield MailCoreInterface.Imap.fetch_messages (imap_session, folder.name, 0, folder.highest_uid, true);

        database.update_messages_for_folder (messages, folder);

        return messages;
    }

    public async string get_html_for_message (Message message) {
        return yield MailCoreInterface.Imap.get_html_for_message (imap_session, message.folder.name, message);
    }

    public void send_message (Message message) {
        message.from = address;

        MailCoreInterface.Smtp.send_message (smtp_session, message);
    }
}
