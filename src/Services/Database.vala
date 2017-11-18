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

    private Gda.Connection connection;

    construct {
        connection = Gda.Connection.open_from_string (null, "SQLite://DB_DIR=.;DB_NAME=db.db", null, Gda.ConnectionOptions.NONE);
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
                                       data_model_iter.get_value_for_field ("id").get_string (),
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
                continue;
            }

            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (MESSAGES_TABLE);
            builder.add_field_value_as_gvalue ("id", current_message.id);
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

    public void update_messages_for_folder (Gee.Collection <Message> messages, Folder folder) {
        var hashed_messages = new Gee.HashSet <string> ();
        foreach (var existing_message in get_messages_for_folder (folder)) {
            hashed_messages.add(existing_message.id);
        }

        foreach (var current_message in messages) {
            //@TODO || message does nto belong to this identity
            if (!hashed_messages.contains (current_message.id)) {
                warning ("Unable to find message %s to update its flags", current_message.id);
                continue;
            }

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
