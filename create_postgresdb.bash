#!/usr/bin/env bash
# Copyright 2025 by moshix
# This script creates the required PostgreSQL database schema for tsu BBS
# Usage: ./create_postgres_db.bash [config_file]
# Default config file: tsu.cnf

CONFIG_FILE="${1:-tsu.cnf}"
LOG_FILE="postgres_schema_creation.log"
SQL_FILE="$(mktemp)"

# Function to read config value
get_config_value() {
    local key="$1"
    local config_file="$2"
    grep "^$key=" "$config_file" | cut -d'=' -f2 | tr -d '"'
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found." >&2
    echo "Please ensure the configuration file exists and contains PostgreSQL settings." >&2
    exit 1
fi

# Read database configuration
DB_TYPE=$(get_config_value "db" "$CONFIG_FILE")
DB_HOST=$(get_config_value "db_host" "$CONFIG_FILE")
DB_PORT=$(get_config_value "db_port" "$CONFIG_FILE")
DB_USER=$(get_config_value "db_user" "$CONFIG_FILE")
DB_PASSWORD=$(get_config_value "db_password" "$CONFIG_FILE")
DB_NAME=$(get_config_value "db_name" "$CONFIG_FILE")

# Verify this is configured for PostgreSQL
if [ "$DB_TYPE" != "pg" ]; then
    echo "Error: Database type is not set to 'pg' in $CONFIG_FILE" >&2
    echo "Please set db=pg in your configuration file to use PostgreSQL." >&2
    exit 1
fi

# Verify all required PostgreSQL settings are present
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Missing PostgreSQL configuration in $CONFIG_FILE" >&2
    echo "Required settings: db_host, db_port, db_user, db_password, db_name" >&2
    exit 1
fi

# Check if psql is installed
if ! command -v psql >/dev/null 2>&1; then
    echo "Error: psql (PostgreSQL client) is not installed or not in PATH." >&2
    echo "Please install PostgreSQL client tools before running this script." >&2
    echo "" >&2
    echo "Installation instructions:" >&2
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client" >&2
    echo "  macOS:         brew install postgresql" >&2
    echo "  CentOS/RHEL:   sudo yum install postgresql" >&2
    echo "  Fedora:        sudo dnf install postgresql" >&2
    exit 1
fi

echo "Found PostgreSQL client: $(psql --version | head -1)"
echo "Connecting to PostgreSQL server: $DB_HOST:$DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"

# Test connection
export PGPASSWORD="$DB_PASSWORD"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    echo "Error: Cannot connect to PostgreSQL server." >&2
    echo "Please check your connection settings and ensure the server is running." >&2
    exit 1
fi

echo "Connection successful!"

# Check if database exists
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" 2>/dev/null)

if [ "$DB_EXISTS" = "1" ]; then
    echo "Database '$DB_NAME' already exists."
    read -p "Do you want to drop and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Dropping existing database..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "DROP DATABASE \"$DB_NAME\";" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "Aborted. Database was not modified."
        exit 1
    fi
fi

# Create database
echo "Creating database '$DB_NAME'..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE \"$DB_NAME\";" 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create database." >&2
    exit 1
fi

# Write the PostgreSQL schema to a temporary file
cat > "$SQL_FILE" <<'EOF'
-- PostgreSQL schema for TSU BBS
-- Converted from SQLite schema with PostgreSQL-specific adaptations
-- Improved based on migration experience

-- Set encoding and locale
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE CHECK (length(username) > 0),
    password_hash TEXT NOT NULL CHECK (length(password_hash) > 0),
    email TEXT NOT NULL CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$'),
    is_admin INTEGER DEFAULT 0 CHECK (is_admin IN (0, 1)),
    is_moderator INTEGER DEFAULT 0 CHECK (is_moderator IN (0, 1)),
    karma INTEGER DEFAULT 0,
    last_login TIMESTAMP NULL,
    city TEXT,
    country TEXT,
    units TEXT DEFAULT 'imperial' CHECK (units IN ('metric', 'imperial')),
    stocks TEXT DEFAULT '',
    calendar_preferences TEXT DEFAULT '{}',
    codepage TEXT DEFAULT 'CP437' CHECK (codepage IN ('CP437', 'CP310', '')),
    confirm_delete INTEGER DEFAULT 1 CHECK (confirm_delete IN (0, 1))
);

CREATE TABLE conferences (
    conference_id SERIAL PRIMARY KEY,
    conference_name TEXT NOT NULL UNIQUE CHECK (length(conference_name) > 0),
    description TEXT DEFAULT '',
    admin_only INTEGER DEFAULT 0 CHECK (admin_only IN (0, 1)),
    moderator_only INTEGER DEFAULT 0 CHECK (moderator_only IN (0, 1)),
    banned TEXT DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE topics (
    topic_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL CHECK (length(trim(title)) > 0),
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    view_count INTEGER DEFAULT 0 CHECK (view_count >= 0),
    color TEXT DEFAULT '',
    conference_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (conference_id) REFERENCES conferences(conference_id) ON DELETE SET NULL
);

CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    topic_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL CHECK (length(trim(content)) > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    FOREIGN KEY (topic_id) REFERENCES topics(topic_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE likes (
    like_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    is_like INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE(post_id, user_id)
);

CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
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
    activity_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    activity_type TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address TEXT,
    virtual_session INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE market (
    item_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price TEXT NOT NULL,
    item_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE chat (
    message_id SERIAL PRIMARY KEY,
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
    note_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE topic_notification_optouts (
    optout_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    topic_id INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
    FOREIGN KEY (topic_id) REFERENCES topics (topic_id) ON DELETE CASCADE,
    UNIQUE(user_id, topic_id)
);

CREATE TABLE blocked_senders (
    block_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    sender_email TEXT NOT NULL CHECK (sender_email ~ '^[^@]+@[^@]+\.[^@]+$'),
    blocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    blocked_count INTEGER DEFAULT 0 NOT NULL,
    last_blocked_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id, sender_email)
);

CREATE TABLE conference_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    conference_id INTEGER NOT NULL,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notification_enabled INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (conference_id) REFERENCES conferences(conference_id) ON DELETE CASCADE,
    UNIQUE(user_id, conference_id)
);

-- Create indexes for performance
CREATE INDEX idx_chat_created_at ON chat(created_at);
CREATE INDEX idx_chat_room_id ON chat(room_id);
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_updated_at ON notes(updated_at);
CREATE INDEX idx_topic_notification_optouts ON topic_notification_optouts(user_id, topic_id);
CREATE INDEX idx_blocked_senders_user ON blocked_senders(user_id);
CREATE INDEX idx_blocked_senders_email ON blocked_senders(user_id, sender_email);
CREATE INDEX idx_conferences_name ON conferences(conference_name);
CREATE INDEX idx_topics_conference_id ON topics(conference_id);
CREATE INDEX idx_topics_user_id ON topics(user_id);
CREATE INDEX idx_topics_created_at ON topics(created_at);
CREATE INDEX idx_conference_subscriptions_user ON conference_subscriptions(user_id);
CREATE INDEX idx_conference_subscriptions_conference ON conference_subscriptions(conference_id);
CREATE INDEX idx_conference_subscriptions_notifications ON conference_subscriptions(conference_id, notification_enabled);

-- Insert initial admin user (admin/admin) - password hashed with SHA-256
INSERT INTO users (username, password_hash, email, is_admin, is_moderator, karma, city, country, units, stocks, calendar_preferences)
VALUES ('admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'admin@example.com', 1, 1, 0, 'System', 'System', 'imperial', '', '{}');

-- Insert noreply user (noreply/noreply) - password hashed with SHA-256
INSERT INTO users (username, password_hash, email, is_admin, is_moderator, karma, city, country, units, stocks, calendar_preferences)
VALUES ('noreply', 'c032f1b2c07148d5c19afa6c6dcaef998abf76f863089c04eab52133c0ee0815', 'noreply@example.com', 0, 0, 0, 'System', 'System', 'imperial', '', '{}');

-- Insert default conferences
INSERT INTO conferences (conference_name, description) VALUES
('General', 'General discussion topics'),
('3270BBS', 'Discussion about 3270 BBS software'),
('User content', 'User-generated content and discussions');

-- Insert default conference subscriptions for admin user
INSERT INTO conference_subscriptions (user_id, conference_id, notification_enabled)
SELECT 1, conference_id, 1 FROM conferences;

-- Insert default conference subscriptions for noreply user
INSERT INTO conference_subscriptions (user_id, conference_id, notification_enabled)
SELECT 2, conference_id, 1 FROM conferences;

-- Verify users were created successfully
SELECT 'Users created:' as status;
SELECT user_id, username, email, is_admin, is_moderator FROM users WHERE username IN ('admin', 'noreply');

-- Schema improvements based on migration experience:
-- 1. Added UTF-8 encoding settings for better text handling
-- 2. Added CHECK constraints for data validation
-- 3. Improved foreign key constraints with CASCADE/SET NULL actions
-- 4. Added NOT NULL constraints on timestamp fields
-- 5. Added validation for email format, usernames, and content length
-- 6. Created admin user (username: admin, password: admin)
-- 7. Created noreply user (username: noreply, password: noreply)
EOF

# Execute the schema creation
echo "Creating database schema..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_FILE" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ PostgreSQL database schema created successfully!"
    echo "Database: $DB_NAME"
    echo "Host: $DB_HOST:$DB_PORT"
    echo "User: $DB_USER"
    echo ""
    echo "You can now start the TSU BBS application with PostgreSQL backend."
    echo "Make sure your tsu.cnf file has db=pg configured."
else
    echo ""
    echo "❌ Error: Schema creation failed. Check $LOG_FILE for details."
    exit 1
fi

# Clean up
rm -f "$SQL_FILE"
unset PGPASSWORD

echo "Log file: $LOG_FILE"
