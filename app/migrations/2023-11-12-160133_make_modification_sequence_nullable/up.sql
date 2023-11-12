CREATE TABLE messages_new (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    folder_id INTEGER NOT NULL,
    time_received TIMESTAMP NOT NULL,
    "from" TEXT NOT NULL,
    "to" TEXT NOT NULL,
    cc TEXT NOT NULL,
    bcc TEXT NOT NULL,
    content TEXT,
    "references" TEXT NOT NULL,
    in_reply_to TEXT NOT NULL,
    uid INTEGER NOT NULL,
    modification_sequence INTEGER NULL,
    seen BOOLEAN NOT NULL,
    flagged BOOLEAN NOT NULL,
    draft BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL
);

INSERT INTO messages_new SELECT * FROM messages;
DROP TABLE messages;
ALTER TABLE messages_new RENAME TO messages;