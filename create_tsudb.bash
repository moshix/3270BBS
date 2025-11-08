#!/usr/bin/env bash
# Copyright 2025 by moshix
# this script needs to be run before starting the applicaiton the first time
# it creates the required database schema in sqlite3 database tsu.db 
# 

DB_FILE="tsu.db"
LOG_FILE="schema_creation.log"
SQL_FILE="$(mktemp)"

# Check if sqlite3 is installed
if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "Error: sqlite3 is not installed or not in PATH." >&2
    echo "Please install sqlite3 before running this script." >&2
    echo "" >&2
    echo "Installation instructions:" >&2
    echo "  Ubuntu/Debian: sudo apt-get install sqlite3" >&2
    echo "  macOS:         brew install sqlite3" >&2
    echo "  CentOS/RHEL:   sudo yum install sqlite" >&2
    echo "  Fedora:        sudo dnf install sqlite" >&2
    exit 1
fi

# Check sqlite3 version and functionality
SQLITE_VERSION=$(sqlite3 -version 2>/dev/null | cut -d' ' -f1)
if [ -z "$SQLITE_VERSION" ]; then
    echo "Error: sqlite3 is installed but not functioning properly." >&2
    exit 1
fi

echo "Found sqlite3 version: $SQLITE_VERSION"

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
    is_moderator INTEGER DEFAULT 0,
    karma INTEGER DEFAULT 0,
    last_login TIMESTAMP NULL,
    city TEXT,
    country TEXT,
    units TEXT DEFAULT 'imperial' CHECK (units IN ('metric', 'imperial')),
    stocks TEXT DEFAULT '',
    codepage TEXT DEFAULT 'CP437' CHECK (codepage IN ('CP437', 'CP310', ''))
);

CREATE TABLE conferences (
    conference_id INTEGER PRIMARY KEY AUTOINCREMENT,
    conference_name TEXT NOT NULL UNIQUE,
    description TEXT DEFAULT '',
    admin_only INTEGER DEFAULT 0,
    moderator_only INTEGER DEFAULT 0,
    banned TEXT DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE topics (
    topic_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    view_count INTEGER DEFAULT 0,
    color TEXT DEFAULT '',
    conference_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (conference_id) REFERENCES conferences(conference_id)
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
    virtual_session INTEGER DEFAULT 1,
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
    virtual_session INTEGER DEFAULT 1,
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

CREATE INDEX idx_chat_created_at ON chat(created_at);
CREATE INDEX idx_chat_room_id ON chat(room_id);
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_updated_at ON notes(updated_at);
CREATE INDEX idx_topic_notification_optouts ON topic_notification_optouts(user_id, topic_id);
CREATE INDEX idx_conferences_name ON conferences(conference_name);
CREATE INDEX idx_topics_conference_id ON topics(conference_id);
CREATE INDEX idx_topics_user_id ON topics(user_id);
CREATE INDEX idx_topics_created_at ON topics(created_at);

-- Insert initial admin user (admin/admin) - password hashed with SHA-256
INSERT INTO users (username, password_hash, email, is_admin)
VALUES ('admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'admin@example.com', 1);

-- Insert noreply user (noreply/noreply) - password hashed with SHA-256
INSERT INTO users (username, password_hash, email, is_admin)
VALUES ('noreply', 'c032f1b2c07148d5c19afa6c6dcaef998abf76f863089c04eab52133c0ee0815', 'noreply@example.com', 0);

CREATE TABLE conference_subscriptions (
    subscription_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    conference_id INTEGER NOT NULL,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notification_enabled INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (conference_id) REFERENCES conferences(conference_id) ON DELETE CASCADE,
    UNIQUE(user_id, conference_id)
);

CREATE INDEX idx_conference_subscriptions_user ON conference_subscriptions(user_id);
CREATE INDEX idx_conference_subscriptions_conference ON conference_subscriptions(conference_id);
CREATE INDEX idx_conference_subscriptions_notifications ON conference_subscriptions(conference_id, notification_enabled);

-- Insert default General conference
INSERT INTO conferences (conference_name, description)
VALUES ('General', 'Default conference for general discussions');
EOF

# Create the database and apply schema
echo "Creating SQLite database $DB_FILE..."
if sqlite3 "$DB_FILE" < "$SQL_FILE" 2> "$LOG_FILE"; then
    # Success - check if database file was actually created
    if [ -f "$DB_FILE" ] && [ -s "$DB_FILE" ]; then
        echo "Database created successfully with initial users (admin, noreply)."
        echo "admin has password admin. noreply has password noreply."
        echo "***** CHANGE THE PASSWORDS FOR USERS ADMIN AND NOREPLY UPON FIRST LOGON!! *****"
        
        # Show database info
        echo ""
        echo "Database info:"
        echo "  File: $DB_FILE"
        echo "  Size: $(du -h "$DB_FILE" | cut -f1)"
        echo "  Tables created: $(sqlite3 "$DB_FILE" ".tables" | wc -w)"
        
        # Clean up SQL file and log file on success
        rm -f "$SQL_FILE"
        rm -f "$LOG_FILE"
        exit 0
    else
        echo "Error: Database file was not created properly." >&2
        exit 1
    fi
else
    # Failure
    echo "Error creating schema or inserting users." >&2
    if [ -s "$LOG_FILE" ]; then
        echo "Error details:" >&2
        cat "$LOG_FILE" >&2
    fi
    echo "Check $LOG_FILE for more details." >&2
    
    # Clean up SQL file but keep log file for debugging
    rm -f "$SQL_FILE"
    exit 1
fi

