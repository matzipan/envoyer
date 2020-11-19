CREATE TABLE attachments (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    message_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    character_set TEXT NOT NULL,
    content_id TEXT NOT NULL,
    content_location TEXT NOT NULL,
    part_id TEXT NOT NULL,
    encoding INTEGER NOT NULL,
    data BLOB NOT NULL,
    is_inline INTEGER NOT NULL
);
CREATE TABLE folders (
    folder_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    folder_name TEXT NOT NULL,
    owning_identity TEXT NOT NULL,
    flags INTEGER NOT NULL,
    unread_count INTEGER NOT NULL,
    total_count INTEGER NOT NULL
);
CREATE TABLE identities (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    email_address TEXT NOT NULL,
    gmail_refresh_token TEXT NOT NULL,
    identity_type TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    full_name TEXT NOT NULL,
    account_name TEXT NOT NULL
);
CREATE TABLE messages (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    owning_folder TEXT NOT NULL,
    time_received INTEGER NOT NULL,
    "from" TEXT NOT NULL,
    sender TEXT NOT NULL,
    "to" TEXT NOT NULL,
    cc TEXT NOT NULL,
    bcc TEXT NOT NULL,
    html_content TEXT NOT NULL,
    plain_text_content TEXT NOT NULL,
    "references" TEXT NOT NULL,
    in_reply_to TEXT NOT NULL,
    uid INTEGER NOT NULL,
    modification_sequence INTEGER NOT NULL,
    seen BOOLEAN NOT NULL,
    flagged BOOLEAN NOT NULL,
    draft BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL
);