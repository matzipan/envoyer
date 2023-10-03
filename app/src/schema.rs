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
        gmail_refresh_token -> Text,
        identity_type -> Text,
        expires_at -> Timestamp,
        full_name -> Text,
        account_name -> Text,
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
        modification_sequence -> BigInt,
        seen -> Bool,
        flagged -> Bool,
        draft -> Bool,
        deleted -> Bool,
    }
}

allow_tables_to_appear_in_same_query!(attachments, folders, identities, messages,);
