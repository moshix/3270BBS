#!/usr/bin/env bash
# Copyright 2025 by moshix
# This script subscribes all users to a specified conference
# Usage: ./subscribe_users.bash <conference_name>
#
# The script will:
# 1. Check if the conference exists
# 2. Get all users from the database
# 3. Subscribe each user to the conference (ignoring already subscribed users)
# 4. Report the results

set -euo pipefail

DB_FILE="tsu.db"
CONFERENCE_NAME="${1:-}"

# Function to display usage
usage() {
    echo "Usage: $0 <conference_name>"
    echo ""
    echo "This script subscribes all users to the specified conference."
    echo "If a user is already subscribed, their subscription is ignored (no error)."
    echo ""
    echo "Examples:"
    echo "  $0 \"General\""
    echo "  $0 \"Tech Discussion\""
    echo "  $0 \"Announcements\""
    exit 1
}

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function to check if sqlite3 is available
check_sqlite3() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "Error: sqlite3 is not installed or not in PATH." >&2
        echo "Please install sqlite3 before running this script." >&2
        exit 1
    fi
}

# Function to check if database exists
check_database() {
    if [ ! -f "$DB_FILE" ]; then
        echo "Error: Database file '$DB_FILE' not found." >&2
        echo "Please run create_tsudb.bash first to create the database." >&2
        exit 1
    fi
}

# Function to validate conference name
validate_conference_name() {
    local conf_name="$1"
    
    # Check if conference name is empty
    if [ -z "$conf_name" ]; then
        echo "Error: Conference name cannot be empty." >&2
        usage
    fi
    
    # Check if conference name is too long (max 50 characters for safety)
    if [ ${#conf_name} -gt 50 ]; then
        echo "Error: Conference name is too long (max 50 characters)." >&2
        exit 1
    fi
}

# Function to check if conference exists
check_conference_exists() {
    local conf_name="$1"
    local count
    local sql_result
    
    # Use properly escaped query to prevent SQL injection
    local escaped_name
    escaped_name=$(printf '%s' "$conf_name" | sed "s/'/''/g")
    sql_result=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM conferences WHERE conference_name = '$escaped_name';" 2>&1)
    
    # Check if sqlite3 command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Database query failed while checking conference existence." >&2
        echo "SQLite error: $sql_result" >&2
        exit 1
    fi
    
    # Validate that result is a number
    if ! [[ "$sql_result" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid response from database when checking conference existence." >&2
        echo "Expected number, got: '$sql_result'" >&2
        exit 1
    fi
    
    count="$sql_result"
    
    if [ "$count" -eq 0 ]; then
        echo "❌ ERROR: Conference '$conf_name' does not exist!" >&2
        echo "" >&2
        echo "The conference name must match EXACTLY (case-sensitive)." >&2
        echo "" >&2
        echo "📋 Available conferences in the database:" >&2
        
        # Safe query for available conferences
        local available_conferences
        available_conferences=$(sqlite3 "$DB_FILE" "SELECT conference_name FROM conferences ORDER BY conference_name;" 2>&1)
        if [ $? -eq 0 ] && [ -n "$available_conferences" ]; then
            echo "$available_conferences" | sed 's/^/  📌 /' >&2
        else
            echo "  (Unable to retrieve conference list)" >&2
        fi
        echo "" >&2
        echo "💡 Usage examples:" >&2
        echo "  ./subscribe_users.bash \"General\"" >&2
        echo "  ./subscribe_users.bash \"3270BBS\"" >&2
        echo "  ./subscribe_users.bash \"Coding\"" >&2
        echo "" >&2
        echo "Note: Conference names are case-sensitive and must be quoted if they contain spaces." >&2
        exit 1
    fi
    
    # Plausibility check: should have exactly 1 conference with this name
    if [ "$count" -gt 1 ]; then
        echo "Error: Database integrity issue - multiple conferences with name '$conf_name' found." >&2
        exit 1
    fi
    
    return 0
}

# Function to get conference ID
get_conference_id() {
    local conf_name="$1"
    local sql_result
    
    # Use properly escaped query to prevent SQL injection
    local escaped_name
    escaped_name=$(printf '%s' "$conf_name" | sed "s/'/''/g")
    sql_result=$(sqlite3 "$DB_FILE" "SELECT conference_id FROM conferences WHERE conference_name = '$escaped_name';" 2>&1)
    
    # Check if sqlite3 command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Database query failed while getting conference ID." >&2
        echo "SQLite error: $sql_result" >&2
        return 1
    fi
    
    # Validate that result is a positive integer
    if ! [[ "$sql_result" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Invalid conference ID returned from database." >&2
        echo "Expected positive integer, got: '$sql_result'" >&2
        return 1
    fi
    
    echo "$sql_result"
    return 0
}

# Function to get all user IDs
get_all_user_ids() {
    local sql_result
    
    sql_result=$(sqlite3 "$DB_FILE" "SELECT user_id FROM users ORDER BY user_id;" 2>&1)
    
    # Check if sqlite3 command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Database query failed while getting user IDs." >&2
        echo "SQLite error: $sql_result" >&2
        return 1
    fi
    
    # Validate that all lines are positive integers
    if [ -n "$sql_result" ]; then
        while IFS= read -r line; do
            if ! [[ "$line" =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: Invalid user ID returned from database: '$line'" >&2
                return 1
            fi
        done <<< "$sql_result"
    fi
    
    echo "$sql_result"
    return 0
}

# Function to get total user count
get_total_users() {
    local sql_result
    
    sql_result=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;" 2>&1)
    
    # Check if sqlite3 command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Database query failed while getting user count." >&2
        echo "SQLite error: $sql_result" >&2
        return 1
    fi
    
    # Validate that result is a non-negative integer
    if ! [[ "$sql_result" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid user count returned from database." >&2
        echo "Expected non-negative integer, got: '$sql_result'" >&2
        return 1
    fi
    
    echo "$sql_result"
    return 0
}

# Function to get already subscribed users count
get_already_subscribed_count() {
    local conference_id="$1"
    local sql_result
    
    # Validate conference_id is a positive integer
    if ! [[ "$conference_id" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Invalid conference ID parameter: '$conference_id'" >&2
        return 1
    fi
    
    sql_result=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM conference_subscriptions WHERE conference_id = $conference_id;" 2>&1)
    
    # Check if sqlite3 command succeeded
    if [ $? -ne 0 ]; then
        echo "Error: Database query failed while getting subscription count." >&2
        echo "SQLite error: $sql_result" >&2
        return 1
    fi
    
    # Validate that result is a non-negative integer
    if ! [[ "$sql_result" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid subscription count returned from database." >&2
        echo "Expected non-negative integer, got: '$sql_result'" >&2
        return 1
    fi
    
    echo "$sql_result"
    return 0
}

# Function to subscribe all users to conference
subscribe_all_users() {
    local conference_id="$1"
    local conf_name="$2"
    local total_users
    local already_subscribed
    local user_ids
    local subscribed_count=0
    local skipped_count=0
    
    # Get data with error checking
    total_users=$(get_total_users)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get total user count." >&2
        return 1
    fi
    
    already_subscribed=$(get_already_subscribed_count "$conference_id")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get subscription count." >&2
        return 1
    fi
    
    # Plausibility check: subscription count shouldn't exceed total users
    if [ "$already_subscribed" -gt "$total_users" ]; then
        echo "Error: Database integrity issue - more subscriptions ($already_subscribed) than users ($total_users)." >&2
        return 1
    fi
    
    log "Starting subscription process..."
    log "Conference: '$conf_name' (ID: $conference_id)"
    log "Total users in system: $total_users"
    log "Already subscribed users: $already_subscribed"
    
    # Get all user IDs with error checking
    user_ids=$(get_all_user_ids)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get user IDs." >&2
        return 1
    fi
    
    if [ -z "$user_ids" ]; then
        log "No users found in the database."
        return 0
    fi
    
    # Subscribe each user with proper error handling
    log "Processing user subscriptions..."
    
    # Count actual user IDs for validation
    local actual_user_count
    actual_user_count=$(echo "$user_ids" | wc -l)
    
    # Plausibility check: user ID count should match total users
    if [ "$actual_user_count" -ne "$total_users" ]; then
        echo "Error: User ID count mismatch. Expected $total_users, got $actual_user_count." >&2
        return 1
    fi
    
    while IFS= read -r user_id; do
        if [ -n "$user_id" ]; then
            # Validate user_id is a positive integer
            if ! [[ "$user_id" =~ ^[1-9][0-9]*$ ]]; then
                echo "Error: Invalid user ID encountered: '$user_id'" >&2
                return 1
            fi
            
            # Check if user is already subscribed with error handling
            local is_subscribed
            local subscription_check_result
            subscription_check_result=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM conference_subscriptions WHERE user_id = $user_id AND conference_id = $conference_id;" 2>&1)
            
            if [ $? -ne 0 ]; then
                echo "Error: Database query failed while checking subscription for user $user_id." >&2
                echo "SQLite error: $subscription_check_result" >&2
                return 1
            fi
            
            # Validate subscription check result
            if ! [[ "$subscription_check_result" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid subscription check result for user $user_id: '$subscription_check_result'" >&2
                return 1
            fi
            
            is_subscribed="$subscription_check_result"
            
            # Plausibility check: subscription count should be 0 or 1 (due to UNIQUE constraint)
            if [ "$is_subscribed" -gt 1 ]; then
                echo "Error: Database integrity issue - user $user_id has $is_subscribed subscriptions to conference $conference_id." >&2
                return 1
            fi
            
            if [ "$is_subscribed" -eq 0 ]; then
                # Subscribe the user with error handling
                local insert_result
                insert_result=$(sqlite3 "$DB_FILE" "INSERT INTO conference_subscriptions (user_id, conference_id) VALUES ($user_id, $conference_id);" 2>&1)
                
                if [ $? -ne 0 ]; then
                    echo "Error: Failed to subscribe user $user_id to conference $conference_id." >&2
                    echo "SQLite error: $insert_result" >&2
                    return 1
                fi
                
                ((subscribed_count++))
                
                # Get username for logging with error handling
                local username
                username=$(sqlite3 "$DB_FILE" "SELECT username FROM users WHERE user_id = $user_id;" 2>&1)
                
                if [ $? -ne 0 ] || [ -z "$username" ]; then
                    username="(unknown)"
                fi
                
                log "  ✓ Subscribed user: $username (ID: $user_id)"
            else
                ((skipped_count++))
                
                # Get username for logging with error handling
                local username
                username=$(sqlite3 "$DB_FILE" "SELECT username FROM users WHERE user_id = $user_id;" 2>&1)
                
                if [ $? -ne 0 ] || [ -z "$username" ]; then
                    username="(unknown)"
                fi
                
                log "  - Skipped user: $username (ID: $user_id) - already subscribed"
            fi
        fi
    done <<< "$user_ids"
    
    # Final report with validation
    local final_subscribed
    final_subscribed=$(get_already_subscribed_count "$conference_id")
    if [ $? -ne 0 ]; then
        echo "Error: Failed to get final subscription count." >&2
        return 1
    fi
    
    # Plausibility checks for final results
    local expected_final_count=$((already_subscribed + subscribed_count))
    if [ "$final_subscribed" -ne "$expected_final_count" ]; then
        echo "Error: Final subscription count mismatch. Expected $expected_final_count, got $final_subscribed." >&2
        return 1
    fi
    
    local total_processed=$((subscribed_count + skipped_count))
    if [ "$total_processed" -ne "$total_users" ]; then
        echo "Error: Total processed count mismatch. Expected $total_users, got $total_processed." >&2
        return 1
    fi
    
    echo ""
    echo "========================================"
    echo "       SUBSCRIPTION RESULTS"
    echo "========================================"
    echo "Conference: '$conf_name'"
    echo ""
    echo "📊 SUMMARY:"
    echo "  • Total users in system: $total_users"
    echo "  • Users already subscribed: $skipped_count"
    echo "  • NEW USERS SUBSCRIBED: $subscribed_count"
    echo "  • Total users now subscribed: $final_subscribed"
    echo ""
    
    if [ "$subscribed_count" -gt 0 ]; then
        echo "✅ SUCCESS: Subscribed $subscribed_count new users to '$conf_name'"
        echo ""
        log "✓ Successfully subscribed $subscribed_count new users to '$conf_name'"
    else
        echo "ℹ️  INFO: All $total_users users were already subscribed to '$conf_name'"
        echo ""
        log "ℹ All users were already subscribed to '$conf_name'"
    fi
    
    echo "========================================"
    
    return 0
}

# Main execution
main() {
    # Check arguments
    if [ $# -ne 1 ]; then
        echo "Error: Exactly one argument (conference name) is required." >&2
        usage
    fi
    
    # Initialize
    check_sqlite3
    check_database
    validate_conference_name "$CONFERENCE_NAME"
    
    log "Starting bulk subscription script for conference: '$CONFERENCE_NAME'"
    
    # Check if conference exists
    check_conference_exists "$CONFERENCE_NAME"
    
    # Confirm conference was found
    echo "✅ Conference '$CONFERENCE_NAME' found in database."
    
    # Get conference ID with error handling
    CONFERENCE_ID=$(get_conference_id "$CONFERENCE_NAME")
    
    if [ $? -ne 0 ] || [ -z "$CONFERENCE_ID" ]; then
        echo "Error: Could not retrieve conference ID for '$CONFERENCE_NAME'." >&2
        exit 1
    fi
    
    # Confirm action with user
    echo ""
    echo "This will subscribe ALL users to the conference: '$CONFERENCE_NAME'"
    echo "Users already subscribed will be skipped (no duplicates will be created)."
    echo ""
    read -p "Do you want to continue? (y/N): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Operation cancelled by user."
        exit 0
    fi
    
    # Perform the subscription with error handling
    if subscribe_all_users "$CONFERENCE_ID" "$CONFERENCE_NAME"; then
        echo ""
        echo "🎉 SCRIPT COMPLETED SUCCESSFULLY!"
        echo ""
        log "Script completed successfully."
        exit 0
    else
        echo ""
        echo "❌ SCRIPT FAILED!"
        echo "Error: Subscription process failed." >&2
        exit 1
    fi
}

# Run main function
main "$@"
