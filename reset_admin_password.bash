#!/bin/bash
# TSU BBS Password Migration Script
# This script safely converts plain text passwords to SHA-256 hashes
# Copyright 2025 by moshix

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored status messages
print_status() {
    echo -e "${YELLOW}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${BLUE}[!]${NC} $1"
}

# Function to check if a string is a valid SHA-256 hash
is_sha256_hash() {
    local hash=$1
    # SHA-256 hashes are 64 characters long and contain only hexadecimal digits
    if [[ ${#hash} -eq 64 && "$hash" =~ ^[a-fA-F0-9]+$ ]]; then
        return 0
    fi
    return 1
}

# Function to detect database password format
detect_password_format() {
    local db_file=$1
    local admin_hash=$(sqlite3 "$db_file" "SELECT password_hash FROM users WHERE is_admin = 1 LIMIT 1;")
    
    if [ -z "$admin_hash" ]; then
        echo "error"
        return
    fi
    
    if is_sha256_hash "$admin_hash"; then
        echo "hashed"
    else
        echo "plain"
    fi
}

# Function to hash password using SHA-256
hash_password() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

# Function to validate password
validate_password() {
    local password=$1
    if [ ${#password} -lt 6 ]; then
        return 1
    fi
    return 0
}

# Check if sqlite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    print_error "sqlite3 is not installed. Please install it first."
    exit 1
fi

# Database file path
DB_FILE="tsu.db"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    print_error "Database file '$DB_FILE' not found!"
    exit 1
fi

# Detect password format
print_status "Analyzing database password format..."
PASSWORD_FORMAT=$(detect_password_format "$DB_FILE")

case "$PASSWORD_FORMAT" in
    "hashed")
        print_status "Detected hashed password format (SHA-256)"
        VERSION_WARNING="This database is using SHA-256 hashed passwords (version 27.5+)"
        ;;
    "plain")
        print_status "Detected plain text password format"
        VERSION_WARNING="This database is using plain text passwords (pre-27.5)"
        ;;
    *)
        print_error "Could not determine password format!"
        exit 1
        ;;
esac

# Display version warning and get confirmation
echo
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ⚠️  IMPORTANT WARNING ⚠️                      ║"
echo "╟────────────────────────────────────────────────────────────────╢"
echo "║ $VERSION_WARNING"
echo "║                                                                ║"
echo "║ The script will automatically adapt to your database version.  ║"
echo "║ A backup will be created before making any changes.            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

# Ask for confirmation
read -p "Are you sure you want to continue? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_error "Operation cancelled by user"
    exit 1
fi

# Create backup
BACKUP_FILE="tsu.db.$(date +%Y%m%d_%H%M%S).bak"
print_status "Creating backup..."
cp "$DB_FILE" "$BACKUP_FILE"
if [ $? -eq 0 ]; then
    print_success "Backup created: $BACKUP_FILE"
else
    print_error "Failed to create backup!"
    exit 1
fi

# Get admin username
ADMIN_USER=$(sqlite3 "$DB_FILE" "SELECT username FROM users WHERE is_admin = 1 LIMIT 1;")
if [ -z "$ADMIN_USER" ]; then
    print_error "No admin user found in database!"
    exit 1
fi

print_status "Found admin user: $ADMIN_USER"

# Get new password (with confirmation)
while true; do
    echo
    read -s -p "Enter new password for $ADMIN_USER: " password
    echo
    if ! validate_password "$password"; then
        print_error "Password must be at least 6 characters long!"
        continue
    fi
    
    read -s -p "Confirm new password: " password2
    echo
    
    if [ "$password" = "$password2" ]; then
        break
    else
        print_error "Passwords do not match! Please try again."
    fi
done

# Process password according to detected format
if [ "$PASSWORD_FORMAT" = "hashed" ]; then
    print_status "Using SHA-256 hashing for password..."
    final_password=$(hash_password "$password")
else
    print_status "Storing password in plain text format..."
    final_password="$password"
fi

# Update the database
print_status "Updating admin password..."
sqlite3 "$DB_FILE" "UPDATE users SET password_hash = '$final_password' WHERE username = '$ADMIN_USER';"

if [ $? -eq 0 ]; then
    print_success "Password successfully updated for admin user: $ADMIN_USER"
    if [ "$PASSWORD_FORMAT" = "hashed" ]; then
        print_success "Password was hashed using SHA-256"
    else
        print_warning "Password was stored in plain text (compatible with pre-27.5)"
    fi
    print_success "A backup of the original database was created: $BACKUP_FILE"
else
    print_error "Failed to update password!"
    print_status "The original database is backed up at: $BACKUP_FILE"
    exit 1
fi
