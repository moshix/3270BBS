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
echo -e "${YELLOW} Only run this script if you have a database prior to 3270BBS 27.5!!! ${NC}"

# Ask for confirmation to proceed
echo
read -p  "Do you want to proceed with password migration? (yes/no): " -r
echo -e "${RED}User response: $REPLY${NC}"
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Migration cancelled by user.${NC}"
    exit 0
fi
echo

echo -e "${RED} ok, so I will hash all passwords. Did you make a backup of your database? ${NC}"

echo
read -p "Backup exists? (yes/no): " -r
echo -e "${RED}User response: $REPLY${NC}"
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Migration cancelled by user.${NC}"
    exit 0
fi
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

# Create backup directory
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/tsu.db.backup.$TIMESTAMP"

print_status "Creating backup..."
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
        echo "  �� $username: Already hashed (${hash_length} chars)"
    fi
done

echo
print_status "Starting password migration..."

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
        echo "⏭️  Skipping $username: already hashed"
    fi
done

echo
print_status "Verifying migration..."

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
TOTAL_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users;")
HASHED_USERS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM users WHERE LENGTH(password_hash) = 64;")
PLAIN_USERS=$((TOTAL_USERS - HASHED_USERS))

echo "  Total users: $TOTAL_USERS"
echo "  Hashed passwords: $HASHED_USERS"
echo "  Plain text passwords: $PLAIN_USERS"

if [ $PLAIN_USERS -eq 0 ]; then
    echo
    print_success "Migration completed successfully!"
    echo "All passwords are now properly hashed."
    echo "You can now start the TSU application."
else
    echo
    print_warning "Warning: Some passwords are still plain text!"
    echo "Please check the output above for details."
fi

echo
print_status "Backup saved as: $BACKUP_FILE"
print_warning "Remember to keep your backup safe!"
