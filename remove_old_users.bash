#!/usr/bin/env bash

DB_FILE="tsu.db"  # <-- Replace with your actual database file

sqlite3 "$DB_FILE" <<'EOF'
BEGIN TRANSACTION;

-- Create temporary table for inactive users
DROP TABLE IF EXISTS tmp_inactive_users;
CREATE TEMP TABLE tmp_inactive_users(user_id INTEGER);

-- Populate it with users who haven't logged in for over 40 days
INSERT INTO tmp_inactive_users(user_id)
SELECT user_id FROM users
WHERE last_login IS NOT NULL AND last_login < datetime('now', '-40 days');

-- Delete from dependent tables
DELETE FROM topic_notification_optouts WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM user_activity WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM messages WHERE sender_id IN (SELECT user_id FROM tmp_inactive_users)
                     OR recipient_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM likes WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM posts WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM topics WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM activity WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM market WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM chat WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);
DELETE FROM notes WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);

-- Delete the users themselves
DELETE FROM users WHERE user_id IN (SELECT user_id FROM tmp_inactive_users);

-- Cleanup
DROP TABLE tmp_inactive_users;

COMMIT;
EOF
#!/bin/bash
