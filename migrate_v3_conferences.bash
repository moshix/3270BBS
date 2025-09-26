#!/bin/bash

# migrate_v3_conferences.bash
# Migration script to upgrade TSU database from v2 (string-based conferences) to v3 (normalized conferences)
# This script migrates the database structure to support the new normalized conference model

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLD_DB_PATH="/tmp/3270BBS/tsu.db"
BACKUP_SUFFIX="_pre_conference_migration_$(date +%Y%m%d_%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if database file exists and is accessible
check_database() {
    local db_path="$1"
    if [[ ! -f "$db_path" ]]; then
        print_error "Database file not found: $db_path"
        return 1
    fi
    
    if [[ ! -r "$db_path" ]]; then
        print_error "Database file not readable: $db_path"
        return 1
    fi
    
    if [[ ! -w "$db_path" ]]; then
        print_error "Database file not writable: $db_path"
        return 1
    fi
    
    # Test if it's a valid SQLite database
    if ! sqlite3 "$db_path" "SELECT 1;" >/dev/null 2>&1; then
        print_error "Invalid SQLite database: $db_path"
        return 1
    fi
    
    return 0
}

# Function to check if migration is needed
needs_migration() {
    local db_path="$1"
    
    # Check if conferences table exists
    local conferences_table_exists=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='conferences';" 2>/dev/null || echo "0")
    
    # Check if topics table has conference_id column
    local conference_id_exists=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM pragma_table_info('topics') WHERE name='conference_id';" 2>/dev/null || echo "0")
    
    if [[ "$conferences_table_exists" -eq 0 ]] || [[ "$conference_id_exists" -eq 0 ]]; then
        return 0  # Migration needed
    fi
    
    # Check if there are topics with NULL conference_id that need migration
    local topics_need_migration=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM topics WHERE conference_id IS NULL;" 2>/dev/null || echo "0")
    
    if [[ "$topics_need_migration" -gt 0 ]]; then
        return 0  # Migration needed
    fi
    
    return 1  # No migration needed
}

# Function to create backup
create_backup() {
    local db_path="$1"
    local backup_path="${db_path}${BACKUP_SUFFIX}"
    
    print_status "Creating backup: $backup_path"
    
    if ! cp "$db_path" "$backup_path"; then
        print_error "Failed to create backup"
        return 1
    fi
    
    print_success "Backup created successfully"
    return 0
}

# Function to create conferences table
create_conferences_table() {
    local db_path="$1"
    
    print_status "Creating conferences table..."
    
    local sql="
    CREATE TABLE IF NOT EXISTS conferences (
        conference_id INTEGER PRIMARY KEY AUTOINCREMENT,
        conference_name TEXT NOT NULL UNIQUE,
        description TEXT DEFAULT '',
        admin_only INTEGER DEFAULT 0,
        moderator_only INTEGER DEFAULT 0,
        banned TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE INDEX IF NOT EXISTS idx_conferences_name ON conferences(conference_name);"
    
    if ! sqlite3 "$db_path" "$sql"; then
        print_error "Failed to create conferences table"
        return 1
    fi
    
    print_success "Conferences table created"
    return 0
}

# Function to add conference_id column to topics table
add_conference_id_column() {
    local db_path="$1"
    
    print_status "Adding conference_id column to topics table..."
    
    # Check if column already exists
    local column_exists=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM pragma_table_info('topics') WHERE name='conference_id';")
    
    if [[ "$column_exists" -eq 0 ]]; then
        if ! sqlite3 "$db_path" "ALTER TABLE topics ADD COLUMN conference_id INTEGER;"; then
            print_error "Failed to add conference_id column"
            return 1
        fi
        print_success "conference_id column added to topics table"
    else
        print_warning "conference_id column already exists in topics table"
    fi
    
    # Add foreign key constraint via index (SQLite doesn't support adding foreign keys to existing tables)
    if ! sqlite3 "$db_path" "CREATE INDEX IF NOT EXISTS idx_topics_conference_id ON topics(conference_id);"; then
        print_warning "Failed to create index on conference_id (non-critical)"
    fi
    
    return 0
}

# Function to populate conferences table with existing conference names
populate_conferences() {
    local db_path="$1"
    
    print_status "Discovering existing conferences from topics..."
    
    # Get all unique conference names from topics table
    local conferences=$(sqlite3 "$db_path" "SELECT DISTINCT COALESCE(conference, 'General') FROM topics WHERE COALESCE(conference, 'General') != '' ORDER BY conference;")
    
    if [[ -z "$conferences" ]]; then
        print_warning "No conferences found in topics table, creating default 'General' conference"
        conferences="General"
    fi
    
    print_status "Found conferences: $(echo "$conferences" | tr '\n' ', ' | sed 's/,$//')"
    
    # Insert conferences into conferences table
    local conference_count=0
    while IFS= read -r conf_name; do
        if [[ -n "$conf_name" ]]; then
            # Set descriptions for known conferences based on the current database
            local description=""
            case "$conf_name" in
                "General") description="Default conference for general discussions" ;;
                "Hello from") description="hello from any country or any emulator" ;;
                "Voting") description="call to action!" ;;
                "3270BBS") description="Discussions about features, requests, bugs, and general comments about this BBS application." ;;
                "VM/370") description="Help with VM/370" ;;
                "3270 emulators") description="Everything about 3270 emulators from Mac7 to Linux" ;;
                "Coding") description="Everything about writing code, or as we used to call it in the past, programming." ;;
                "MVS Help Desk") description="" ;;
                "User content") description="Stuff that people want to share" ;;
                "MVS 3.8 Help Desk") description="help with MVS 3.8" ;;
                "Moshix") description="Personal conference for Moshix" ;;
                *) description="Migrated conference from legacy system" ;;
            esac
            
            if sqlite3 "$db_path" "INSERT OR IGNORE INTO conferences (conference_name, description) VALUES ('$conf_name', '$description');"; then
                conference_count=$((conference_count + 1))
                print_status "  Added conference: $conf_name"
            else
                print_warning "  Failed to add conference: $conf_name"
            fi
        fi
    done <<< "$conferences"
    
    print_success "Populated $conference_count conferences"
    return 0
}

# Function to update topics with conference_id
update_topics_conference_ids() {
    local db_path="$1"
    
    print_status "Updating topics with conference_id values..."
    
    # Update all topics to have the correct conference_id based on their conference name
    local sql="
    UPDATE topics 
    SET conference_id = (
        SELECT conference_id 
        FROM conferences 
        WHERE conference_name = COALESCE(topics.conference, 'General')
    )
    WHERE conference_id IS NULL;"
    
    local updated_count=$(sqlite3 "$db_path" "BEGIN TRANSACTION; $sql SELECT changes(); COMMIT;")
    
    if [[ $? -eq 0 ]]; then
        print_success "Updated $updated_count topics with conference_id"
    else
        print_error "Failed to update topics with conference_id"
        return 1
    fi
    
    # Handle any topics that still don't have a conference_id (shouldn't happen, but safety check)
    local orphaned_topics=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM topics WHERE conference_id IS NULL;")
    
    if [[ "$orphaned_topics" -gt 0 ]]; then
        print_warning "Found $orphaned_topics topics without conference_id, assigning to 'General'"
        
        # Get or create General conference ID
        local general_id=$(sqlite3 "$db_path" "SELECT conference_id FROM conferences WHERE conference_name = 'General' LIMIT 1;")
        
        if [[ -z "$general_id" ]]; then
            sqlite3 "$db_path" "INSERT INTO conferences (conference_name, description) VALUES ('General', 'Default conference for general discussions');"
            general_id=$(sqlite3 "$db_path" "SELECT conference_id FROM conferences WHERE conference_name = 'General' LIMIT 1;")
        fi
        
        sqlite3 "$db_path" "UPDATE topics SET conference_id = $general_id WHERE conference_id IS NULL;"
        print_success "Assigned orphaned topics to General conference (ID: $general_id)"
    fi
    
    return 0
}

# Function to remove legacy conference column
remove_legacy_conference_column() {
    local db_path="$1"
    
    print_status "Removing legacy conference text column..."
    
    # SQLite doesn't support DROP COLUMN directly, so we need to recreate the table
    local sql="
    BEGIN TRANSACTION;
    
    -- Create new topics table without the legacy conference column
    CREATE TABLE topics_new (
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
    
    -- Copy data from old table to new table (excluding the conference column)
    INSERT INTO topics_new (topic_id, title, user_id, created_at, view_count, color, conference_id)
    SELECT topic_id, title, user_id, created_at, view_count, color, conference_id
    FROM topics;
    
    -- Drop the old table
    DROP TABLE topics;
    
    -- Rename the new table
    ALTER TABLE topics_new RENAME TO topics;
    
    -- Recreate indexes
    CREATE INDEX IF NOT EXISTS idx_topics_conference_id ON topics(conference_id);
    CREATE INDEX IF NOT EXISTS idx_topics_user_id ON topics(user_id);
    CREATE INDEX IF NOT EXISTS idx_topics_created_at ON topics(created_at);
    
    COMMIT;"
    
    if ! sqlite3 "$db_path" "$sql"; then
        print_error "Failed to remove legacy conference column"
        return 1
    fi
    
    print_success "Legacy conference column removed successfully"
    return 0
}

# Function to verify migration
verify_migration() {
    local db_path="$1"
    
    print_status "Verifying migration..."
    
    # Check that conferences table exists and has data
    local conf_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM conferences;")
    print_status "  Conferences in database: $conf_count"
    
    # Check that all topics have conference_id
    local topics_with_conf_id=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM topics WHERE conference_id IS NOT NULL;")
    local total_topics=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM topics;")
    print_status "  Topics with conference_id: $topics_with_conf_id/$total_topics"
    
    # Check that all conference_ids reference valid conferences
    local valid_refs=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM topics t JOIN conferences c ON t.conference_id = c.conference_id;")
    print_status "  Topics with valid conference references: $valid_refs/$total_topics"
    
    # Check that legacy conference column is gone
    local legacy_column_exists=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM pragma_table_info('topics') WHERE name='conference';")
    print_status "  Legacy conference column removed: $([ "$legacy_column_exists" -eq 0 ] && echo "Yes" || echo "No")"
    
    if [[ "$topics_with_conf_id" -eq "$total_topics" ]] && [[ "$valid_refs" -eq "$total_topics" ]] && [[ "$conf_count" -gt 0 ]] && [[ "$legacy_column_exists" -eq 0 ]]; then
        print_success "Migration verification passed!"
        return 0
    else
        print_error "Migration verification failed!"
        return 1
    fi
}

# Function to show summary
show_summary() {
    local db_path="$1"
    
    print_status "Migration Summary:"
    echo "=================="
    
    # Show conference statistics
    echo "Conferences:"
    sqlite3 "$db_path" "SELECT conference_id, conference_name, description FROM conferences ORDER BY conference_id;" | while IFS='|' read -r id name desc; do
        echo "  $id: $name - $desc"
    done
    
    echo ""
    echo "Topics by Conference:"
    sqlite3 "$db_path" "
    SELECT c.conference_name, COUNT(t.topic_id) as topic_count
    FROM conferences c
    LEFT JOIN topics t ON c.conference_id = t.conference_id
    GROUP BY c.conference_id, c.conference_name
    ORDER BY topic_count DESC;" | while IFS='|' read -r name count; do
        echo "  $name: $count topics"
    done
    
    echo ""
    print_success "Migration completed successfully!"
}

# Main migration function
main() {
    print_status "Starting TSU Database Conference Migration (v2 -> v3)"
    print_status "=================================================="
    
    # Check if database exists
    if ! check_database "$OLD_DB_PATH"; then
        exit 1
    fi
    
    # Check if migration is needed
    if ! needs_migration "$OLD_DB_PATH"; then
        print_success "Database is already migrated or migration not needed"
        exit 0
    fi
    
    print_status "Database needs migration"
    
    # Create backup
    if ! create_backup "$OLD_DB_PATH"; then
        exit 1
    fi
    
    # Perform migration steps
    print_status "Starting migration process..."
    
    if ! create_conferences_table "$OLD_DB_PATH"; then
        print_error "Migration failed at step 1: creating conferences table"
        exit 1
    fi
    
    if ! add_conference_id_column "$OLD_DB_PATH"; then
        print_error "Migration failed at step 2: adding conference_id column"
        exit 1
    fi
    
    if ! populate_conferences "$OLD_DB_PATH"; then
        print_error "Migration failed at step 3: populating conferences"
        exit 1
    fi
    
    if ! update_topics_conference_ids "$OLD_DB_PATH"; then
        print_error "Migration failed at step 4: updating topic conference_ids"
        exit 1
    fi
    
    if ! remove_legacy_conference_column "$OLD_DB_PATH"; then
        print_error "Migration failed at step 5: removing legacy conference column"
        exit 1
    fi
    
    if ! verify_migration "$OLD_DB_PATH"; then
        print_error "Migration failed verification"
        exit 1
    fi
    
    show_summary "$OLD_DB_PATH"
    
    print_success "All migration steps completed successfully!"
    print_status "Backup created: ${OLD_DB_PATH}${BACKUP_SUFFIX}"
    print_status "Database is now ready for use with the new TSU application"
}

# Handle script arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --help|-h)
            echo "TSU Database Conference Migration Script"
            echo "Usage: $0 [--help|--dry-run]"
            echo ""
            echo "This script migrates TSU database from v2 (string conferences) to v3 (normalized conferences)"
            echo "The script will:"
            echo "  1. Create a backup of the database"
            echo "  2. Create the conferences table"
            echo "  3. Add conference_id column to topics table"
            echo "  4. Populate conferences from existing topic conference names"
            echo "  5. Update all topics with proper conference_id references"
            echo "  6. Remove the legacy conference text column"
            echo "  7. Verify the migration"
            echo ""
            echo "Database location: $OLD_DB_PATH"
            exit 0
            ;;
        --dry-run)
            print_status "DRY RUN MODE - No changes will be made"
            print_status "Would migrate database: $OLD_DB_PATH"
            if check_database "$OLD_DB_PATH"; then
                if needs_migration "$OLD_DB_PATH"; then
                    print_status "Migration would be performed"
                else
                    print_status "No migration needed"
                fi
            else
                print_error "Database check failed"
            fi
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
fi

# Run main function
main
