#!/usr/bin/env bash
# Copyright 2025 by moshix
# this script needs to be run before starting the applicaiton the first time
# it creates the required database schema in sqlite3 database tsu.db 
# 

DB_FILE="tsu.db"
LOG_FILE="schema_creation.log"
SQL_FILE="$(mktemp)"

# Check if database already exists
if [ -f "$DB_FILE" ]; then
    echo "Database $DB_FILE already exists. Remove it first if you want to recreate." >&2
    exit 1
fi

# Write the schema and inserts to a temporary file
cat > "$SQL_FILE" <<'EOF'
PRAGMA foreign_keys = ON;

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    email TEXT NOT NULL,
    is_admin INTEGER DEFAULT 0,
    karma INTEGER DEFAULT 0,
    last_login TIMESTAMP NULL,
    city TEXT,
    country TEXT,
    units TEXT DEFAULT 'imperial' CHECK (units IN ('metric', 'imperial')),
    stocks TEXT DEFAULT '',
    calendar_preferences TEXT DEFAULT '{}'
);

CREATE TABLE topics (
    topic_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    color TEXT DEFAULT '',
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE posts (
    post_id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE likes (
    like_id INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    is_like INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE(post_id, user_id)
);

CREATE TABLE messages (
    message_id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read INTEGER DEFAULT 0,
    replied INTEGER DEFAULT 0,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id)
);

CREATE TABLE activity (
    activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    activity_type TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE market (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price TEXT NOT NULL,
    item_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE chat (
    message_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    room_id TEXT DEFAULT 'global',
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE user_activity (
    user_id INTEGER PRIMARY KEY,
    last_activity TIMESTAMP NOT NULL,
    activity_type TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE notes (
    note_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE topic_notification_optouts (
    optout_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    topic_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES topics (topic_id) ON DELETE CASCADE,
    UNIQUE(user_id, topic_id) -- One opt-out per user per topic
);

CREATE TABLE calendar_events (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    duration INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_chat_created_at ON chat(created_at);
CREATE INDEX idx_chat_room_id ON chat(room_id);
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_updated_at ON notes(updated_at);
CREATE INDEX idx_topic_notification_optouts ON topic_notification_optouts(user_id, topic_id);
CREATE INDEX idx_calendar_events_user_time ON calendar_events(user_id, start_time);

-- Insert initial admin user (admin/admin)
INSERT INTO users (username, password_hash, email, is_admin)
VALUES ('admin', 'admin', 'admin@example.com', 1);

-- Insert noreply user (noreply/noreply)
INSERT INTO users (username, password_hash, email, is_admin)
VALUES ('noreply', 'noreply', 'noreply@example.com', 0);
EOF

# Create the database and apply schema
echo "Creating SQLite database $DB_FILE..."
sqlite3 "$DB_FILE" < "$SQL_FILE" 2> "$LOG_FILE"

# Clean up SQL file
rm -f "$SQL_FILE"

# Check for errors
if [ $? -ne 0 ]; then
    echo "Error creating schema or inserting users. Check $LOG_FILE for details." >&2
    exit 1
else
    echo "Database created successfully with initial users (admin, noreply)."
    exit 0
fi

