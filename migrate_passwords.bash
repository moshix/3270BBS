#!/bin/bash

# TSU BBS Password Migration Script
# This script safely converts plain text passwords to SHA-256 hashes
# Copyright 2025 by moshix

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
reset=`tput sgr0`
NC='\033[0m' # No Color

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

# Configuration
DB_FILE="tsu.db"
BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "    TSU BBS Password Migration Script"
echo "    Copyright 2025 by moshix"
echo "=========================================="
echo

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    print_error "Database file $DB_FILE not found!"
    exit 1
fi

# Check if sqlite3 is available
if ! command -v sqlite3 &> /dev/null; then
    print_error "sqlite3 is not installed. Please install it first."
    exit 1
fi

# Analyze current password state
print_status "Analyzing current password format..."

# Get password format statistics
TOTAL_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
HASHED_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE LENGTH(password_hash) = 64 AND password_hash REGEXP '^[0-9a-fA-F]+$';")
PLAIN_USERS=$((TOTAL_USERS - HASHED_USERS))

echo
echo "Current database status:"
echo "  Total users: $TOTAL_USERS"
echo "  Users with hashed passwords: $HASHED_USERS"
echo "  Users with plain text passwords: $PLAIN_USERS"
echo

# Display appropriate warning based on analysis
if [ $PLAIN_USERS -eq 0 ]; then
    echo -e "${RED}All passwords are already hashed! Migration is not needed.${NC}"
    echo -e "This database appears to be from 3270BBS 27.5 or later.${NC}"
    exit 0
    echo
    read -p "Do you still want to proceed with migration? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Migration cancelled - no action needed."
        exit 0
    fi
    print_warning "Proceeding with verification only..."
else
    echo -e "${YELLOW}This database appears to be from before 3270BBS 27.5${NC}"
    echo -e "${YELLOW}Password migration is recommended!${NC}"
    echo
    read -p "Do you want to proceed with password migration? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Migration cancelled by user."
        exit 0
    fi
fi

echo
echo -e "${RED}Important: A backup of your database is required before proceeding.${NC}"
echo
read -p "Do you have a backup of your database? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_warning "Please make a backup first!"
    exit 0
fi

# Create additional backup
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/tsu.db.backup.$TIMESTAMP"

print_status "Creating additional backup..."
cp "$DB_FILE" "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    print_success "Backup created: $BACKUP_FILE"
else
    print_error "Failed to create backup!"
    exit 1
fi

echo
print_status "Analyzing current passwords..."

# Get all users and their current password hashes
USERS_DATA=$(sqlite3 "$DB_FILE" "SELECT user_id, username, password_hash FROM users;")

if [ -z "$USERS_DATA" ]; then
    print_error "No users found in database!"
    exit 1
fi

echo "Found users:"
echo "$USERS_DATA" | while IFS='|' read -r user_id username password_hash; do
    hash_length=${#password_hash}
    if [ $hash_length -lt 64 ]; then
        echo "  👤 $username: Plain text password (${hash_length} chars)"
    else
        if [[ "$password_hash" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "  ✅ $username: Valid SHA-256 hash"
        else
            echo "  ⚠️  $username: Invalid hash format"
        fi
    fi
done

if [ $PLAIN_USERS -eq 0 ]; then
    echo
    print_status "Verifying existing hashes..."
else
    echo
    print_status "Starting password migration..."
fi

# Process each user
echo "$USERS_DATA" | while IFS='|' read -r user_id username password_hash; do
    hash_length=${#password_hash}
    
    if [ $hash_length -lt 64 ]; then
        echo "🔄 Hashing password for user: $username"
        
        # Hash the password using sha256sum
        hashed_password=$(echo -n "$password_hash" | sha256sum | cut -d' ' -f1)
        
        # Update the database
        sqlite3 "$DB_FILE" "UPDATE users SET password_hash = '$hashed_password' WHERE user_id = $user_id;"
        
        if [ $? -eq 0 ]; then
            echo "  ✅ $username: ${password_hash:0:8}... → ${hashed_password:0:16}..."
        else
            echo "  ❌ Failed to update password for $username"
        fi
    else
        if [[ "$password_hash" =~ ^[0-9a-fA-F]+$ ]]; then
            echo "✓ Verified hash for $username: ${password_hash:0:16}..."
        else
            print_warning "Invalid hash format for $username"
        fi
    fi
done

echo
print_status "Verifying final state..."

# Show final state
echo "Final password status:"
sqlite3 "$DB_FILE" "SELECT username, LENGTH(password_hash) as hash_length, substr(password_hash, 1, 16) as hash_preview FROM users ORDER BY username;" | while IFS='|' read -r username hash_length hash_preview; do
    if [ $hash_length -eq 64 ]; then
        echo "  ✅ $username: Hashed (${hash_preview}...)"
    else
        echo "  ❌ $username: Still plain text (${hash_length} chars)"
    fi
done

echo
print_status "Migration Summary:"
FINAL_TOTAL=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
FINAL_HASHED=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE LENGTH(password_hash) = 64;")
FINAL_PLAIN=$((FINAL_TOTAL - FINAL_HASHED))

echo "  Total users: $FINAL_TOTAL"
echo "  Hashed passwords: $FINAL_HASHED"
echo "  Plain text passwords: $FINAL_PLAIN"

if [ $FINAL_PLAIN -eq 0 ]; then
    echo
    print_success "All passwords are properly hashed!"
    if [ $PLAIN_USERS -eq 0 ]; then
        echo "No migration was needed - all passwords were already in correct format."
    else
        echo "Migration completed successfully."
    fi
    echo "You can now start the TSU application."
else
    echo
    print_error "Warning: Some passwords are still in plain text!"
    echo "Please check the output above for details."
fi

echo
print_status "Backup saved as: $BACKUP_FILE"
print_warning "Remember to keep your backup safe!"
