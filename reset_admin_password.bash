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

# Display version warning and get confirmation
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ⚠️  IMPORTANT WARNING ⚠️                      ║"
echo "╟────────────────────────────────────────────────────────────────╢"
echo "║ This script is designed for 3270BBS version 27.5 and higher.   ║"
echo "║ Using it with older versions may corrupt your database.        ║"
echo "║                                                                ║"
echo "║ Please verify your TSU BBS version before continuing.          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo

# Ask for confirmation
read -p "Are you sure you want to continue? (yes/no): " confirm
if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
    print_error "Operation cancelled by user"
    exit 1
fi

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

# Hash the password
hashed_password=$(hash_password "$password")

# Update the database
print_status "Updating admin password..."
sqlite3 "$DB_FILE" "UPDATE users SET password_hash = '$hashed_password' WHERE username = '$ADMIN_USER';"

if [ $? -eq 0 ]; then
    print_success "Password successfully updated for admin user: $ADMIN_USER"
    print_success "A backup of the original database was created: $BACKUP_FILE"
else
    print_error "Failed to update password!"
    print_status "The original database is backed up at: $BACKUP_FILE"
    exit 1
fi
