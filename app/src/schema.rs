table! {
    attachments (id) {
        id -> Integer,
        message_id -> Integer,
        file_name -> Text,
        mime_type -> Text,
        character_set -> Text,
        content_id -> Text,
        content_location -> Text,
        part_id -> Text,
        encoding -> Integer,
        data -> Binary,
        is_inline -> Integer,
    }
}

table! {
    folders (id) {
        id -> Integer,
        folder_name -> Text,
        folder_path -> Text,
        identity_id -> Integer,
        uid_validity -> Nullable<BigInt>,
        flags -> Integer,
    }
}

table! {
    identities (id) {
        id -> Integer,
        email_address -> Text,
        identity_type -> Text,
        full_name -> Text,
        account_name -> Text,
        imap_server_hostname -> Text,
        imap_server_port -> Integer,
        imap_password -> Nullable<Text>,
        imap_use_tls -> Bool,
        imap_use_starttls -> Bool,
        gmail_refresh_token -> Text,
        expires_at -> Timestamp,
    }
}

table! {
    messages (id) {
        id -> Integer,
        message_id -> Text,
        subject -> Text,
        folder_id -> Integer,
        time_received -> Timestamp,
        from -> Text,
        to -> Text,
        cc -> Text,
        bcc -> Text,
        content -> Nullable<Text>,
        references -> Text,
        in_reply_to -> Text,
        uid -> BigInt,
        modification_sequence -> Nullable<BigInt>,
        seen -> Bool,
        flagged -> Bool,
        draft -> Bool,
        deleted -> Bool,
    }
}

allow_tables_to_appear_in_same_query!(attachments, folders, identities, messages,);
