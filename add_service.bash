#!/bin/bash

# Copyright 2025 by moshix
# This is a BBS for 3270 terminals
# All rights reserved by moshix

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Function to detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)
            OS_NAME="Linux"
            ;;
        Darwin*)
            OS_NAME="macOS"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            OS_NAME="Windows"
            ;;
        *)
            OS_NAME="Unknown"
            ;;
    esac
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_NAME="$NAME"
        DISTRO_ID="$ID"
        DISTRO_VERSION="$VERSION_ID"
    elif [ -f /etc/redhat-release ]; then
        DISTRO_NAME=$(cat /etc/redhat-release)
        DISTRO_ID="rhel"
    elif [ -f /etc/debian_version ]; then
        DISTRO_NAME="Debian $(cat /etc/debian_version)"
        DISTRO_ID="debian"
    else
        DISTRO_NAME="Unknown"
        DISTRO_ID="unknown"
    fi
}

# Function to check operating system compatibility
check_os_compatibility() {
    detect_os
    print_status "Detected operating system: $OS_NAME"
    
    if [ "$OS_NAME" != "Linux" ]; then
        print_error "This script is designed for Linux systems only"
        print_error "Detected OS: $OS_NAME"
        print_status "This script creates systemd services which are Linux-specific"
        print_status "For other operating systems, please use appropriate service management tools"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if systemd is available
check_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
        print_error "systemctl not found. This script requires systemd."
        print_error "Your system may be using a different init system."
        exit 1
    fi
}

# Function to check if tsu executable exists
check_tsu_executable() {
    if [ ! -f "./tsu" ]; then
        print_error "TSU executable not found in current directory"
        print_status "Please run INSTALL.bash first to build the application"
        exit 1
    fi
}

# Function to check if service already exists
check_existing_service() {
    local service_file="/etc/systemd/system/tsu.service"
    
    if [ -f "$service_file" ]; then
        print_warning "TSU service already exists at $service_file"
        
        # Check if service is enabled
        if systemctl is-enabled --quiet tsu 2>/dev/null; then
            print_status "TSU service is currently enabled"
        else
            print_status "TSU service exists but is not enabled"
        fi
        
        # Check if service is running
        if systemctl is-active --quiet tsu 2>/dev/null; then
            print_status "TSU service is currently running"
        else
            print_status "TSU service exists but is not running"
        fi
        
        echo
        read -p "Do you want to overwrite the existing service? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Service installation cancelled by user"
            exit 0
        fi
        
        # Stop and disable existing service before overwriting
        print_status "Stopping existing TSU service..."
        systemctl stop tsu 2>/dev/null || true
        
        print_status "Disabling existing TSU service..."
        systemctl disable tsu 2>/dev/null || true
        
        print_status "Removing existing service file..."
        rm -f "$service_file"
        
        print_success "Existing service removed"
    else
        print_status "No existing TSU service found"
    fi
}

# Function to get current working directory
get_working_directory() {
    WORKING_DIR=$(pwd)
    print_status "Working directory: $WORKING_DIR"
}

# Function to create systemd service file
create_systemd_service() {
    local service_file="/etc/systemd/system/tsu.service"
    
    print_status "Creating systemd service file..."
    
    cat > "$service_file" << EOF
# TSU BBS Systemd Service
# Copyright 2025 by moshix
# This is a BBS for 3270 terminals
# All rights reserved by moshix

[Unit]
Description=TSU BBS - 3270 Terminal BBS Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORKING_DIR
ExecStart=$WORKING_DIR/tsu
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=tsu

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$WORKING_DIR

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

    if [ $? -eq 0 ]; then
        print_success "Systemd service file created: $service_file"
    else
        print_error "Failed to create systemd service file"
        exit 1
    fi
}

# Function to reload systemd and enable service
setup_systemd_service() {
    print_status "Reloading systemd daemon..."
    systemctl daemon-reload
    
    if [ $? -eq 0 ]; then
        print_success "Systemd daemon reloaded"
    else
        print_error "Failed to reload systemd daemon"
        exit 1
    fi
    
    print_status "Enabling TSU service..."
    systemctl enable tsu.service
    
    if [ $? -eq 0 ]; then
        print_success "TSU service enabled for startup"
    else
        print_error "Failed to enable TSU service"
        exit 1
    fi
}

# Function to test the service
test_service() {
    print_status "Testing TSU service..."
    
    # Check service status
    if systemctl is-active --quiet tsu; then
        print_success "TSU service is running"
    else
        print_warning "TSU service is not running (this is normal if not started yet)"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet tsu; then
        print_success "TSU service is enabled for startup"
    else
        print_error "TSU service is not enabled"
    fi
}

# Function to show service commands
show_service_commands() {
    echo
    echo "=========================================="
    print_success "TSU BBS Service Installation Complete!"
    echo "=========================================="
    echo
    print_status "Service Management Commands:"
    echo "  Start service:     sudo systemctl start tsu"
    echo "  Stop service:      sudo systemctl stop tsu"
    echo "  Restart service:   sudo systemctl restart tsu"
    echo "  Check status:      sudo systemctl status tsu"
    echo "  View logs:         sudo journalctl -u tsu -f"
    echo "  Disable service:   sudo systemctl disable tsu"
    echo
    print_status "Alternative commands (if systemctl is not available):"
    echo "  Start service:     sudo service tsu start"
    echo "  Stop service:      sudo service tsu stop"
    echo "  Restart service:   sudo service tsu restart"
    echo "  Check status:      sudo service tsu status"
    echo
    print_warning "The service will start automatically on system boot"
    print_warning "To start the service now, run: sudo systemctl start tsu"
    echo
}

# Function to remove service
remove_service() {
    print_status "Removing TSU service..."
    
    # Stop and disable service
    systemctl stop tsu 2>/dev/null || true
    systemctl disable tsu 2>/dev/null || true
    
    # Remove service file
    rm -f /etc/systemd/system/tsu.service
    
    # Reload systemd
    systemctl daemon-reload
    
    print_success "TSU service removed successfully"
}

# Function to show current service status
show_service_status() {
    echo
    print_status "Current TSU Service Status:"
    echo "=================================="
    
    if [ -f "/etc/systemd/system/tsu.service" ]; then
        print_success "Service file exists: /etc/systemd/system/tsu.service"
        
        if systemctl is-enabled --quiet tsu 2>/dev/null; then
            print_success "Service is enabled for startup"
        else
            print_warning "Service is not enabled for startup"
        fi
        
        if systemctl is-active --quiet tsu 2>/dev/null; then
            print_success "Service is currently running"
        else
            print_warning "Service is not currently running"
        fi
        
        echo
        print_status "Recent service logs:"
        journalctl -u tsu --no-pager -n 10 2>/dev/null || print_warning "No recent logs found"
        
    else
        print_warning "TSU service file does not exist"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "    TSU BBS Service Management"
    echo "    Copyright 2025 by moshix"
    echo "=========================================="
    echo
    
    # Check operating system compatibility first
    check_os_compatibility
    
    # Check if running as root
    check_root
    
    # Detect distribution
    detect_distro
    print_status "Detected distribution: $DISTRO_NAME"
    
    # Check if systemd is available
    check_systemd
    
    # Check if tsu executable exists
    check_tsu_executable
    
    # Get working directory
    get_working_directory
    
    # Check for existing service
    check_existing_service
    
    # Ask user for confirmation
    echo
    print_status "This will create a systemd service for TSU BBS"
    print_status "The service will run as root and start automatically on boot"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled by user"
        exit 0
    fi
    
    # Create systemd service
    create_systemd_service
    
    # Setup and enable service
    setup_systemd_service
    
    # Test the service
    test_service
    
    # Show service commands
    show_service_commands
}

# Check command line arguments
case "${1:-}" in
    "status")
        show_service_status
        exit 0
        ;;
    "remove")
        check_os_compatibility
        check_root
        remove_service
        exit 0
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  - Install TSU service"
        echo "  status     - Show current service status"
        echo "  remove     - Remove TSU service"
        echo "  help       - Show this help message"
        echo
        exit 0
        ;;
    "")
        # No arguments, run main installation
        main "$@"
        ;;
    *)
        print_error "Unknown command: $1"
        print_status "Use '$0 help' for usage information"
        exit 1
        ;;
esac 
