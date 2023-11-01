ALTER TABLE identities ADD COLUMN imap_password TEXT;
ALTER TABLE identities ADD COLUMN imap_server_hostname TEXT NOT NULL DEFAULT 'imap.gmail.com';
ALTER TABLE identities ADD COLUMN imap_server_port INTEGER NOT NULL DEFAULT 993;
ALTER TABLE identities ADD COLUMN imap_use_tls BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE identities ADD COLUMN imap_use_starttls BOOLEAN NOT NULL DEFAULT false;