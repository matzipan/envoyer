/*
 * Copyright 2017 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Envoyer.Models;

public class Envoyer.Services.Database : Object {
    private const string FOLDERS_TABLE = "folders";
    private const string MESSAGES_TABLE = "messages";
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
                                                                    "content",          typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "references",               typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "uid",                      typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "modification_sequence",    typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "seen",             typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "flagged",          typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "draft",            typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "deleted",          typeof (uint64), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG
                                                                    );
        is_initialization |= !create_table (operation, e); //@TODO catch issues


        e = null;

        operation = Gda.ServerOperation.prepare_create_table (connection, IDENTITIES_TABLE, e,
                                                                    "id",               typeof (uint64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                    "username",         typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                    "access_token",     typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
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
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
        }
    }

    private Gee.Collection <Address> get_addresses_from_string (string addresses_string) {
        var addresses = addresses_string.split (",");
        var list = new Gee.ArrayList <Address> ();

        foreach (var address in addresses) {
            list.add (new Address.from_string (address));
        }

        return list;
    }

    private Gee.Collection <string> split_references (string references_list_string) {
        var references = references_list_string.split (",");
        var list = new Gee.ArrayList <string> ();

        foreach (var reference in references) {
            list.add (reference.chomp ().chug ());
        }

        return list;
    }

    public Gee.Collection <ConversationThread> get_threads_for_folder (Folder folder) {
        var threader = new Envoyer.Util.ThreadingHelper ();
        return threader.process_messages (get_messages_for_folder (folder));
    }

    public Gee.Collection <Message> get_messages_for_folder (Folder folder) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        var owning_identity_field = builder.add_id ("owning_identity");
        var owning_identity_value = builder.add_expr_value (null, folder.identity.address.email); //@TODO is .email really good enough?
        var owning_identity_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_identity_field, owning_identity_value, 0);
        var owning_folder_field = builder.add_id ("owning_folder");
        var owning_folder_value = builder.add_expr_value (null, folder.name);
        var owning_folder_condition = builder.add_cond (Gda.SqlOperatorType.GEQ, owning_folder_field, owning_folder_value, 0);
        builder.set_where (builder.add_cond (Gda.SqlOperatorType.AND, owning_identity_condition, owning_folder_condition, 0));

        builder.select_add_field ("*", null, null);
        builder.select_add_target (MESSAGES_TABLE, null);
        var statement = builder.get_statement ();

        var data_model = connection.statement_execute_select (statement, null);
        var data_model_iter = data_model.create_iter ();
        var list = new Gee.ArrayList <Message> ();
        data_model_iter.move_to_row (-1);
        while (data_model_iter.move_next ()) {
            var current_message = new Message (null,
                                       new Address.from_string(data_model_iter.get_value_for_field ("from").get_string ()),
                                       new Address.from_string(data_model_iter.get_value_for_field ("sender").get_string ()),
                                       get_addresses_from_string(data_model_iter.get_value_for_field ("to").get_string ()),
                                       get_addresses_from_string(data_model_iter.get_value_for_field ("cc").get_string ()),
                                       get_addresses_from_string(data_model_iter.get_value_for_field ("bcc").get_string ()),
                                       data_model_iter.get_value_for_field ("subject").get_string (),
                                       (time_t) data_model_iter.get_value_for_field ("time_received").get_int (),
                                       split_references(data_model_iter.get_value_for_field ("references").get_string ()),
                                       data_model_iter.get_value_for_field ("message_id").get_string (),
                                       data_model_iter.get_value_for_field ("uid").get_int (),
                                       data_model_iter.get_value_for_field ("modification_sequence").get_int (),
                                       data_model_iter.get_value_for_field ("seen").get_int () != 0,
                                       data_model_iter.get_value_for_field ("flagged").get_int () != 0,
                                       data_model_iter.get_value_for_field ("deleted").get_int () != 0,
                                       data_model_iter.get_value_for_field ("draft").get_int () != 0);
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

    public string join_references (Gee.Collection <string> references) {
        var references_string_builder = new StringBuilder ();

        var first = true;
        foreach (var reference in references) {
            if (!first) {
                references_string_builder.append(",");
            }
            first = false;

            references_string_builder.append (reference); //@TODO also encode "," in the address name
        }

        return references_string_builder.str;
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

            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (MESSAGES_TABLE);
            builder.add_field_value_as_gvalue ("message_id", current_message.id);
            builder.add_field_value_as_gvalue ("uid", current_message.uid);
            builder.add_field_value_as_gvalue ("modification_sequence", current_message.modification_sequence);
            builder.add_field_value_as_gvalue ("subject", current_message.subject);
            builder.add_field_value_as_gvalue ("owning_folder", current_message.folder.name);
            builder.add_field_value_as_gvalue ("owning_identity", current_message.folder.identity.address.email); //@TODO is .email really good enough?
            builder.add_field_value_as_gvalue ("time_received", (long) current_message.time_received);
            builder.add_field_value_as_gvalue ("from", current_message.from.to_string ());
            builder.add_field_value_as_gvalue ("sender", current_message.sender.to_string ());
            builder.add_field_value_as_gvalue ("to", join_addresses (current_message.to));
            builder.add_field_value_as_gvalue ("cc", join_addresses (current_message.cc));
            builder.add_field_value_as_gvalue ("bcc", join_addresses (current_message.bcc));
            builder.add_field_value_as_gvalue ("content", current_message.content);
            builder.add_field_value_as_gvalue ("references", join_references (current_message.references));
            builder.add_field_value_as_gvalue ("seen", (int) current_message.seen);
            builder.add_field_value_as_gvalue ("flagged", (int) current_message.flagged);
            builder.add_field_value_as_gvalue ("draft", (int) current_message.draft);
            builder.add_field_value_as_gvalue ("deleted", (int) current_message.deleted);
            /*builder.add_field_value_as_gvalue ("has_attachment", );*/
            var statement = builder.get_statement ();
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
        }
    }

    public void add_identity (string username, string access_token, string full_name, string account_name) {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
        builder.set_table (IDENTITIES_TABLE);
        builder.add_field_value_as_gvalue ("username", username);
        builder.add_field_value_as_gvalue ("access_token", access_token);
        builder.add_field_value_as_gvalue ("full_name", full_name);
        builder.add_field_value_as_gvalue ("account_name", account_name);
        var statement = builder.get_statement ();
        Gda.Set last_insert_row;
        connection.statement_execute_non_select (statement, null, out last_insert_row);
    }

    public Gee.Collection <Gee.HashMap<string, string>> get_identities () {
        var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);

        builder.select_add_field ("*", null, null);
        builder.select_add_target (IDENTITIES_TABLE, null);
        var statement = builder.get_statement ();

        var data_model = connection.statement_execute_select (statement, null);
        var data_model_iter = data_model.create_iter ();
        var list = new Gee.ArrayList <Gee.HashMap<string, string>> ();
        data_model_iter.move_to_row (-1);
        while (data_model_iter.move_next ()) {
            var user_data = new Gee.HashMap<string, string>();

            user_data["username"] = data_model_iter.get_value_for_field ("username").get_string ();
            user_data["access_token"] = data_model_iter.get_value_for_field ("access_token").get_string ();
            user_data["full_name"] = data_model_iter.get_value_for_field ("full_name").get_string ();
            user_data["account_name"] = data_model_iter.get_value_for_field ("account_name").get_string ();

            list.add (user_data);
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
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
        }
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
