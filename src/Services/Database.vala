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
using Envoyer.Models;

// Some things in libgda-5.0 and its Vala binding are fundamentally 
// broken. For example, it has very poor binary handling as well as 
// poor handling of 32/64 bit integers. I will not make any efforts to
// fix this any further. Maybe I'll just move this whole class to Rust.
public class Envoyer.Services.Database : Object {
    private const string FOLDERS_TABLE = "folders";
    private const string MESSAGES_TABLE = "messages";
    private const string ATTACHMENTS_TABLE = "attachments";
    private const string IDENTITIES_TABLE = "identities";
    private const string DB_FILE_PATH = "db.db";
    // Are we going through the initialization phase? (empty tables in the database)
    public bool is_initialization { get; private set; default = false; }

    private Gda.Connection connection;

    construct {
        //@TODO Improve error handling?
        var db_file = File.new_for_path (DB_FILE_PATH);

        if (!db_file.query_exists ()) {
            try {
                db_file.create (FileCreateFlags.PRIVATE);

                is_initialization = true;
            } catch (Error e) {
                critical ("Error: %s", e.message);
            }
        }

        connection = Gda.Connection.open_from_string (null, "SQLite://DB_DIR=.;DB_NAME=%s".printf (DB_FILE_PATH), null, Gda.ConnectionOptions.NONE);

        Error e = null;

        var operation = Gda.ServerOperation.prepare_create_table (connection, FOLDERS_TABLE, e,
                                                                    "folder_id",        typeof (uint64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                    "folder_name",      typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "owning_identity",  typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "flags",            typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "unread_count",     typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "total_count",      typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG
                                                                    );
        is_initialization |= !create_table (operation, e); //@TODO catch isseus

        e = null;

        operation = Gda.ServerOperation.prepare_create_table (connection, MESSAGES_TABLE, e,
                                                                    "id",               typeof (uint64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                    "message_id",       typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "subject",          typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "owning_folder",    typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "owning_identity",  typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "time_received",    typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "from",             typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "sender",           typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "to",               typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "cc",               typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "bcc",              typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "html_content",         typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "plain_text_content",   typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "references",               typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "in_reply_to",              typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "uid",                      typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "modification_sequence",    typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "seen",             typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "flagged",          typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "draft",            typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "deleted",          typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG
                                                                    );
        is_initialization |= !create_table (operation, e); //@TODO catch issues


        operation = Gda.ServerOperation.prepare_create_table (connection, ATTACHMENTS_TABLE, e,
                                                                    "id",               typeof (uint64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                    "message_id",       typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "file_name",        typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "mime_type",        typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "character_set",    typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "content_id",       typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "content_location", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "part_id",          typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "encoding",         typeof (int64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "data",             typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "is_inline", typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG
                                                                    );
        is_initialization |= !create_table (operation, e); //@TODO catch issues

        e = null;

        operation = Gda.ServerOperation.prepare_create_table (connection, IDENTITIES_TABLE, e,
                                                                    "id",               typeof (uint64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                    "username",         typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "access_token",     typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "refresh_token",    typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "expires_at",       typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "full_name",        typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "account_name",     typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG
                                                                    );
        is_initialization |= !create_table (operation, e); //@TODO catch issues

    }

    // Returns whether the table already existed or not
    public bool create_table (Gda.ServerOperation operation, Error e) {
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                } else {
                    return true;
                }
            }
        }

        return false;
    }

    public Gee.Collection <Folder> get_folders_for_identity (string identity) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        var owning_identity_field = builder.add_id ("owning_identity");
        var owning_identity_value = builder.add_expr_value (null, identity);
        var owning_identity_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_identity_field, owning_identity_value, 0);
        builder.set_where (owning_identity_condition);

        builder.select_add_field ("*", null, null);
        builder.select_add_target (FOLDERS_TABLE, null);
        var statement = builder.get_statement ();

        var data_model = connection.statement_execute_select (statement, null);
        var data_model_iter = data_model.create_iter ();
        var list = new Gee.ArrayList <Folder> ();
        data_model_iter.move_to_row (-1);
        while (data_model_iter.move_next ()) {
            var folder_struct = new Envoyer.FolderStruct ();

            folder_struct.unseen_count = data_model_iter.get_value_for_field ("unread_count").get_int ();
            folder_struct.message_count = data_model_iter.get_value_for_field ("total_count").get_int ();
            folder_struct.recent_count = 0; //@TODO
            folder_struct.uid_next = 0; //@TODO
            folder_struct.uid_validity = 0; //@TODO
            folder_struct.highest_modification_sequence = 0; //@TODO

            var folder_name = data_model_iter.get_value_for_field ("folder_name").get_string ();
            var flags = data_model_iter.get_value_for_field ("flags").get_int ();
            var folder = new Folder (folder_name, flags, folder_struct);

            list.add (folder);
        }

        return list;
    }

    public void set_folders_for_identity (Gee.Collection <Folder> folders, string identity) {
        var hashed_folders = new Gee.HashSet <string> ();
        foreach (var existing_folder in get_folders_for_identity (identity)) {
            hashed_folders.add(existing_folder.name);
        }

        foreach (var item in folders) {
            if (hashed_folders.contains (item.name)) {
                continue;
            }

            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (FOLDERS_TABLE);
            builder.add_field_value_as_gvalue ("folder_name", item.name);
            builder.add_field_value_as_gvalue ("owning_identity", item.identity.address.email); //@TODO is .email really good enough?
            builder.add_field_value_as_gvalue ("flags", item.flags);
            builder.add_field_value_as_gvalue ("unread_count", item.unread_count);
            builder.add_field_value_as_gvalue ("total_count", item.total_count);
            var statement = builder.get_statement ();
            connection.statement_execute_non_select (statement, null, null);
        }

        //@TODO identity_updated ();
    }

    private Gee.Collection <Address> get_addresses_from_string (string addresses_string) {
        var addresses = addresses_string.split (",");
        var list = new Gee.ArrayList <Address> ();

        foreach (var address in addresses) {
            list.add (new Address.from_string (address));
        }

        return list;
    }

    private Gee.List <string> split_strings (string concatenated_list_string) {
        var strings = concatenated_list_string.split (",");
        var list = new Gee.ArrayList <string> ();

        foreach (var current_string in strings) {
            list.add (current_string.chomp ().chug ());
        }

        return list;
    }

    public Gee.Collection <ConversationThread> get_threads_for_folder (Folder folder) {
        var threader = new Envoyer.Util.ThreadingHelper ();
        return threader.process_messages (get_messages_for_folder (folder));
    }

    public Gee.Collection <Message> get_messages_for_folder (Folder folder) {
        var messages_query_builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        var owning_identity_field = messages_query_builder.add_id ("owning_identity");
        var owning_identity_value = messages_query_builder.add_expr_value (null, folder.identity.address.email); //@TODO is .email really good enough?
        var owning_identity_condition = messages_query_builder.add_cond (Gda.SqlOperatorType.EQ, owning_identity_field, owning_identity_value, 0);
        var owning_folder_field = messages_query_builder.add_id ("owning_folder");
        var owning_folder_value = messages_query_builder.add_expr_value (null, folder.name);
        var owning_folder_condition = messages_query_builder.add_cond (Gda.SqlOperatorType.EQ, owning_folder_field, owning_folder_value, 0);
        messages_query_builder.set_where (messages_query_builder.add_cond (Gda.SqlOperatorType.AND, owning_identity_condition, owning_folder_condition, 0));

        messages_query_builder.select_add_field ("*", null, null);
        messages_query_builder.select_add_target (MESSAGES_TABLE, null);
        var messages_query_statement = messages_query_builder.get_statement ();

        var message_query_data_model = connection.statement_execute_select (messages_query_statement, null);
        var messages_iterator = message_query_data_model.create_iter ();
        var list = new Gee.ArrayList <Message> ();
        messages_iterator.move_to_row (-1);
        while (messages_iterator.move_next () && messages_iterator.is_valid ()) {
            // Querying the database for attachments everytime. A future improvement could be to batch them for all the messages in the folder. 
            var attachments_query_builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            
            var message_id_field = attachments_query_builder.add_id ("message_id");
            var message_id_value = attachments_query_builder.add_expr_value (null, messages_iterator.get_value_for_field ("id").get_int ());
            attachments_query_builder.set_where (attachments_query_builder.add_cond (Gda.SqlOperatorType.EQ, message_id_field, message_id_value, 0));

            attachments_query_builder.select_add_field ("*", null, null);
            attachments_query_builder.select_add_target (ATTACHMENTS_TABLE, null);
            var attachments_query_statement = attachments_query_builder.get_statement ();
            
            var attachments_query_data_model = connection.statement_execute_select (attachments_query_statement, null);
            var attachments_iterator = attachments_query_data_model.create_iter ();
            var attachment_list = new Gee.ArrayList <Attachment> ();
            
            attachments_iterator.move_to_row (-1);
            while (attachments_iterator.move_next () && attachments_iterator.is_valid ()) {
                var decoded_data = GLib.Base64.decode (attachments_iterator.get_value_for_field ("data").get_string ());
                unowned uint8[] unowned_decoded_data = (uint8[]) decoded_data;
                var data = new Bytes (unowned_decoded_data);

                var current_attachment = new Attachment.with_data (
                        attachments_iterator.get_value_for_field ("file_name").get_string (),
                        attachments_iterator.get_value_for_field ("mime_type").get_string (),
                        attachments_iterator.get_value_for_field ("character_set").get_string (),
                        attachments_iterator.get_value_for_field ("content_id").get_string (),
                        attachments_iterator.get_value_for_field ("content_location").get_string (),
                        attachments_iterator.get_value_for_field ("part_id").get_string (),
                        // On the following line we get_int instead of int64 because libgda-5.0 has issues with int64 in vala
                        // https://github.com/Alecaddd/sequeler/issues/83
                        // https://bugzilla.gnome.org/show_bug.cgi?id=759792
                        // https://gitlab.gnome.org/GNOME/libgda/issues/13 
                        attachments_iterator.get_value_for_field ("encoding").get_int (),
                        attachments_iterator.get_value_for_field ("is_inline").get_int () != 0,
                        data
                    );
                    
                attachment_list.add (current_attachment);
            }
            
            var current_message = new Message (null,
                                       new Address.from_string(messages_iterator.get_value_for_field ("from").get_string ()),
                                       new Address.from_string(messages_iterator.get_value_for_field ("sender").get_string ()),
                                       get_addresses_from_string(messages_iterator.get_value_for_field ("to").get_string ()),
                                       get_addresses_from_string(messages_iterator.get_value_for_field ("cc").get_string ()),
                                       get_addresses_from_string(messages_iterator.get_value_for_field ("bcc").get_string ()),
                                       messages_iterator.get_value_for_field ("subject").get_string (),
                                       (time_t) messages_iterator.get_value_for_field ("time_received").get_int (),
                                       split_strings(messages_iterator.get_value_for_field ("references").get_string ()),
                                       split_strings(messages_iterator.get_value_for_field ("in_reply_to").get_string ()),
                                       messages_iterator.get_value_for_field ("message_id").get_string (),
                                       messages_iterator.get_value_for_field ("uid").get_int (),
                                       messages_iterator.get_value_for_field ("modification_sequence").get_int (),
                                       messages_iterator.get_value_for_field ("seen").get_int () != 0,
                                       messages_iterator.get_value_for_field ("flagged").get_int () != 0,
                                       messages_iterator.get_value_for_field ("deleted").get_int () != 0,
                                       messages_iterator.get_value_for_field ("draft").get_int () != 0,
                                       attachment_list
                                       );

            current_message.folder = folder;

            current_message.html_content = messages_iterator.get_value_for_field ("html_content").get_string ();
            current_message.plain_text_content = messages_iterator.get_value_for_field ("plain_text_content").get_string ();

            list.add (current_message);
        }

        return list;
    }

    public string join_addresses (Gee.Collection <Address> addresses) {
        var addresses_string_builder = new StringBuilder ();

        var first = true;
        foreach (var address in addresses) {
            if (!first) {
                addresses_string_builder.append(",");
            }
            first = false;

            addresses_string_builder.append (address.to_string ()); //@TODO also encode "," in the address name
        }

        return addresses_string_builder.str;
    }

    public string join_strings (Gee.Collection <string> strings) {
        var joined_string_builder = new StringBuilder ();

        var first = true;
        foreach (var current_string in strings) {
            if (!first) {
                joined_string_builder.append(",");
            }
            first = false;

            joined_string_builder.append (current_string.to_string ()); //@TODO also encode "," in the address name
        }

        return joined_string_builder.str;
    }

    public void set_messages_for_folder (Gee.Collection <Message> messages, Folder folder) {
        var hashed_messages = new Gee.HashSet <string> ();
        foreach (var existing_message in get_messages_for_folder (folder)) {
            hashed_messages.add(existing_message.id);
        }

        foreach (var current_message in messages) {
            //@TODO also take into account identity for multi-account
            if (hashed_messages.contains (current_message.id)) {
                debug ("Message already exists: %u, %s, %s", current_message.uid, current_message.id, current_message.subject);
                continue;
            }

            debug ("Saving message: %u, %s, %s", current_message.uid, current_message.id, current_message.subject);

            var messages_query_builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            messages_query_builder.set_table (MESSAGES_TABLE);
            messages_query_builder.add_field_value_as_gvalue ("message_id", current_message.id);
            messages_query_builder.add_field_value_as_gvalue ("uid", current_message.uid);
            messages_query_builder.add_field_value_as_gvalue ("modification_sequence", current_message.modification_sequence);
            messages_query_builder.add_field_value_as_gvalue ("subject", current_message.subject);
            messages_query_builder.add_field_value_as_gvalue ("owning_folder", current_message.folder.name);
            messages_query_builder.add_field_value_as_gvalue ("owning_identity", current_message.folder.identity.address.email); //@TODO is .email really good enough?
            messages_query_builder.add_field_value_as_gvalue ("time_received", (long) current_message.time_received);
            messages_query_builder.add_field_value_as_gvalue ("from", current_message.from.to_string ());
            messages_query_builder.add_field_value_as_gvalue ("sender", current_message.sender.to_string ());
            messages_query_builder.add_field_value_as_gvalue ("to", join_addresses (current_message.to));
            messages_query_builder.add_field_value_as_gvalue ("cc", join_addresses (current_message.cc));
            messages_query_builder.add_field_value_as_gvalue ("bcc", join_addresses (current_message.bcc));
            messages_query_builder.add_field_value_as_gvalue ("html_content", current_message.html_content);
            messages_query_builder.add_field_value_as_gvalue ("plain_text_content", current_message.plain_text_content);
            messages_query_builder.add_field_value_as_gvalue ("references", join_strings (current_message.references));
            messages_query_builder.add_field_value_as_gvalue ("in_reply_to", join_strings (current_message.in_reply_to));
            messages_query_builder.add_field_value_as_gvalue ("seen", (int) current_message.seen);
            messages_query_builder.add_field_value_as_gvalue ("flagged", (int) current_message.flagged);
            messages_query_builder.add_field_value_as_gvalue ("draft", (int) current_message.draft);
            messages_query_builder.add_field_value_as_gvalue ("deleted", (int) current_message.deleted);
            var messages_query_statement = messages_query_builder.get_statement ();


            Gda.Set last_inserted_rows; 
            connection.statement_execute_non_select (messages_query_statement, null, out last_inserted_rows);
            
            var message_id = last_inserted_rows.get_holder_value ("+0").get_int ();
            
            foreach (var attachment in current_message.all_attachments) {
               var attachments_query_builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
               attachments_query_builder.set_table (ATTACHMENTS_TABLE);

               attachments_query_builder.add_field_value_as_gvalue ("message_id", message_id);
               attachments_query_builder.add_field_value_as_gvalue ("file_name", attachment.file_name);
               attachments_query_builder.add_field_value_as_gvalue ("mime_type", attachment.mime_type);
               attachments_query_builder.add_field_value_as_gvalue ("character_set", attachment.character_set);
               attachments_query_builder.add_field_value_as_gvalue ("content_id", attachment.content_id);
               attachments_query_builder.add_field_value_as_gvalue ("content_location", attachment.content_location);
               attachments_query_builder.add_field_value_as_gvalue ("part_id", attachment.part_id);
               attachments_query_builder.add_field_value_as_gvalue ("encoding", attachment.encoding);
               attachments_query_builder.add_field_value_as_gvalue ("is_inline", (int) attachment.is_inline);

               attachments_query_builder.add_field_value_as_gvalue ("data", GLib.Base64.encode (attachment.data.get_data ()));


               var attachments_statement = attachments_query_builder.get_statement ();

               connection.statement_execute_non_select (attachments_statement, null, null);
            }
        }

        application.folder_updated (folder.name); //@TODO there needs to be a centralized factory of objects, conversation threads so that we can nicely handle updates and signals
    }

    public void add_identity (string username, string access_token, string refresh_token, DateTime expires_at, string full_name, string account_name) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
        builder.set_table (IDENTITIES_TABLE);
        builder.add_field_value_as_gvalue ("username", username);
        builder.add_field_value_as_gvalue ("access_token", access_token);
        builder.add_field_value_as_gvalue ("refresh_token", refresh_token);
        builder.add_field_value_as_gvalue ("expires_at", expires_at.to_unix ());
        builder.add_field_value_as_gvalue ("full_name", full_name);
        builder.add_field_value_as_gvalue ("account_name", account_name);
        var statement = builder.get_statement ();
        connection.statement_execute_non_select (statement, null, null);

        //@TODO identity_added ();
    }

    public void update_identity_access_token_and_expiry (Envoyer.Models.Identity identity, string access_token, DateTime expires_at) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.UPDATE);

        builder.set_table (IDENTITIES_TABLE);
        builder.add_field_value_as_gvalue ("access_token", access_token);
        builder.add_field_value_as_gvalue ("expires_at", expires_at.to_unix ());

        var username_field = builder.add_id ("username");
        var username_value = builder.add_expr_value (null, identity.address.email); //@TODO is .email really good enough?

        builder.set_where (builder.add_cond (Gda.SqlOperatorType.EQ, username_field, username_value, 0));

        var statement = builder.get_statement ();
        connection.statement_execute_non_select (statement, null, null);
    }

    public Gee.List <Envoyer.Models.Identity> get_identities () {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        builder.select_add_field ("*", null, null);
        builder.select_add_target (IDENTITIES_TABLE, null);
        var statement = builder.get_statement ();

        var data_model = connection.statement_execute_select (statement, null);
        var data_model_iter = data_model.create_iter ();
        var list = new Gee.ArrayList <Envoyer.Models.Identity> ();

        data_model_iter.move_to_row (-1);
        while (data_model_iter.move_next ()) {
            var username = data_model_iter.get_value_for_field ("username").get_string ();
            var access_token = data_model_iter.get_value_for_field ("access_token").get_string ();
            var refresh_token = data_model_iter.get_value_for_field ("refresh_token").get_string ();
            var expires_at = new DateTime.from_unix_utc (data_model_iter.get_value_for_field ("expires_at").get_int ());
            var full_name = data_model_iter.get_value_for_field ("full_name").get_string ();
            var account_name = data_model_iter.get_value_for_field ("account_name").get_string ();

            var identity = new Envoyer.Models.Identity (username, access_token, refresh_token, expires_at, full_name, account_name);

            list.add (identity);
        }

        return list;
    }

    public void update_messages_for_folder (Gee.Collection <Message> messages, Folder folder) {
        var hashed_messages = new Gee.HashSet <string> ();
        foreach (var existing_message in get_messages_for_folder (folder)) {
            hashed_messages.add(existing_message.id);
        }

        foreach (var current_message in messages) {
            //@TODO add to if -> || message does nto belong to this identity
            if (!hashed_messages.contains (current_message.id)) {
                warning ("Unable to find message to update its flags: %u, %s, %s", current_message.uid, current_message.id, current_message.subject);
                continue;
            }

            debug ("Updating message: %u, %s", current_message.uid, current_message.id);

            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.UPDATE);
            builder.set_table (MESSAGES_TABLE);
            builder.add_field_value_as_gvalue ("modification_sequence", current_message.modification_sequence);
            builder.add_field_value_as_gvalue ("owning_folder", current_message.folder.name);
            builder.add_field_value_as_gvalue ("seen", (int) current_message.seen);
            builder.add_field_value_as_gvalue ("flagged", (int) current_message.flagged);
            builder.add_field_value_as_gvalue ("draft", (int) current_message.draft);
            builder.add_field_value_as_gvalue ("deleted", (int) current_message.deleted);
            var owning_identity_field = builder.add_id ("owning_identity");
            var owning_identity_value = builder.add_expr_value (null, folder.identity.address.email); //@TODO is .email really good enough?
            var owning_identity_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_identity_field, owning_identity_value, 0);
            var uid_field = builder.add_id ("uid");
            var uid_value = builder.add_expr_value (null, current_message.uid); //@TODO is .email really good enough?
            var uid_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, uid_field, uid_value, 0);
            builder.set_where (builder.add_cond (Gda.SqlOperatorType.AND, owning_identity_condition, uid_condition, 0));
            var statement = builder.get_statement ();
            connection.statement_execute_non_select (statement, null, null);
        }

        application.folder_updated (folder.name); //@TODO there needs to be a centralized factory of objects, conversation threads so that we can nicely handle updates and signals
    }

    public uint get_highest_uid_for_folder (Folder folder) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        var owning_identity_field = builder.add_id ("owning_identity");
        var owning_identity_value = builder.add_expr_value (null, folder.identity.address.email); //@TODO is .email really good enough?
        var owning_identity_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_identity_field, owning_identity_value, 0);
        var owning_folder_field = builder.add_id ("owning_folder");
        var owning_folder_value = builder.add_expr_value (null, folder.name);
        var owning_folder_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_folder_field, owning_folder_value, 0);
        builder.set_where (builder.add_cond (Gda.SqlOperatorType.AND, owning_identity_condition, owning_folder_condition, 0));

        var uid_field = builder.add_id ("uid");
        builder.select_order_by (uid_field, false, null);

        var offset_value = builder.add_expr_value (null, 0);
        var limit_value = builder.add_expr_value (null, 1);
        builder.select_set_limit (limit_value, offset_value);

        builder.select_add_field ("uid", null, null);
        builder.select_add_target (MESSAGES_TABLE, null);
        var statement = builder.get_statement ();

        var data_model = connection.statement_execute_select (statement, null);

        if (data_model.get_n_rows () == 0) {
            return 0;
        } else {
            return data_model.get_value_at (0, 0).get_int ();
        }
    }
}
