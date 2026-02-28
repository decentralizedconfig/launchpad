#!/bin/bash

#############################################
# WebConnect Data Transfer Module
# Handles synchronization and transfer of
# backed up system files
# Version: 1.0.0
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${HOME}/.webconnect"
CONFIG_FILE="${INSTALL_DIR}/config.json"
TRANSFER_LOG="${INSTALL_DIR}/logs/transfer.log"
BACKUP_DIR="${INSTALL_DIR}/backup"
SYSTEM_FILES_DIR="${INSTALL_DIR}/system_files"

#############################################
# Utility Functions
#############################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$TRANSFER_LOG"
}

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_progress() {
    echo -e "${YELLOW}→ $1${NC}"
}

#############################################
# Compression & Encryption
#############################################

compress_backup() {
    local source="$1"
    local destination="$2"
    
    print_progress "Compressing backup..."
    tar -czf "$destination" -C "$(dirname "$source")" "$(basename "$source")" 2>&1 | tee -a "$TRANSFER_LOG"
    
    local size=$(du -h "$destination" | cut -f1)
    print_success "Backup compressed: $size"
    log "Compressed backup to: $destination (Size: $size)"
}

encrypt_backup() {
    local source="$1"
    local output="$2"
    
    print_progress "Encrypting backup..."
    
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        print_error "openssl is required for encryption but not installed"
        log "ERROR: openssl not found"
        return 1
    fi
    
    # Generate random password prompt
    read -s -p "Enter encryption password: " password
    echo
    
    # Encrypt using AES-256
    openssl enc -aes-256-cbc -salt -in "$source" -out "$output" -k "$password" 2>&1 | tee -a "$TRANSFER_LOG"
    
    print_success "Backup encrypted: $output"
    log "Encrypted backup: $output"
}

decrypt_backup() {
    local source="$1"
    local output="$2"
    
    print_progress "Decrypting backup..."
    
    read -s -p "Enter decryption password: " password
    echo
    
    openssl enc -d -aes-256-cbc -in "$source" -out "$output" -k "$password" 2>&1 | tee -a "$TRANSFER_LOG"
    
    print_success "Backup decrypted: $output"
    log "Decrypted backup: $output"
}

#############################################
# Transfer Methods
#############################################

transfer_local() {
    local source="$1"
    local destination="$2"
    
    print_progress "Starting local transfer..."
    
    # Validate destination
    if [ ! -d "$(dirname "$destination")" ]; then
        mkdir -p "$(dirname "$destination")"
    fi
    
    # Copy with progress
    cp -v "$source" "$destination" 2>&1 | tee -a "$TRANSFER_LOG"
    
    # Verify transfer
    if cmp -s "$source" "$destination"; then
        print_success "Local transfer completed and verified"
        log "Local transfer successful: $source -> $destination"
        return 0
    else
        print_error "Transfer verification failed"
        log "ERROR: Transfer verification failed"
        return 1
    fi
}

transfer_sftp() {
    local source="$1"
    local remote_host="$3"
    local remote_path="$4"
    
    print_progress "Starting SFTP transfer..."
    
    if ! command -v scp &> /dev/null; then
        print_error "scp is required but not installed"
        return 1
    fi
    
    # Use scp for SFTP transfer
    scp -v "$source" "${remote_host}:${remote_path}" 2>&1 | tee -a "$TRANSFER_LOG"
    
    if [ $? -eq 0 ]; then
        print_success "SFTP transfer completed"
        log "SFTP transfer successful: $source -> ${remote_host}:${remote_path}"
        return 0
    else
        print_error "SFTP transfer failed"
        log "ERROR: SFTP transfer failed"
        return 1
    fi
}

transfer_http() {
    local source="$1"
    local endpoint="$2"
    
    print_progress "Starting HTTP transfer..."
    
    # Get file size for progress
    local file_size=$(stat -f%z "$source" 2>/dev/null || stat -c%s "$source" 2>/dev/null)
    print_info "Uploading file ($(numfmt --to=iec-i --suffix=B $file_size 2>/dev/null || echo "$file_size bytes"))..."
    
    # Upload with curl
    response=$(curl -s -w "\n%{http_code}" -X POST -F "file=@$source" "$endpoint" 2>&1 | tee -a "$TRANSFER_LOG")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        print_success "HTTP transfer completed"
        log "HTTP transfer successful: $source -> $endpoint (Status: $http_code)"
        return 0
    else
        print_error "HTTP transfer failed (Status: $http_code)"
        log "ERROR: HTTP transfer failed with status $http_code"
        return 1
    fi
}

#############################################
# Backup Management
#############################################

list_backups() {
    print_header "Available Backups"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "No backups found"
        return 1
    fi
    
    echo ""
    ls -lh "$BACKUP_DIR" | grep "^d" | awk '{print $9, "(" $5 ")"}'
    echo ""
}

restore_from_backup() {
    local backup_name="$1"
    local restore_path="${2:-.}"
    
    print_header "Restoring Backup"
    
    local backup_source="$BACKUP_DIR/$backup_name"
    
    if [ ! -d "$backup_source" ]; then
        print_error "Backup not found: $backup_name"
        log "ERROR: Backup not found: $backup_name"
        return 1
    fi
    
    print_progress "Restoring from: $backup_source"
    print_progress "Restoring to: $restore_path"
    
    # Create backup of current files before restore
    mkdir -p "$restore_path/.pre_restore_backup"
    
    # Copy files, preserving structure
    cp -rp "$backup_source"/* "$restore_path/" 2>&1 | tee -a "$TRANSFER_LOG"
    
    print_success "Restore completed to: $restore_path"
    log "Restore completed from $backup_name to $restore_path"
}

create_snapshot() {
    print_progress "Creating system snapshot..."
    
    local snapshot_dir="$BACKUP_DIR/snapshot_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$snapshot_dir"
    
    # Copy system files
    cp -rp "$SYSTEM_FILES_DIR"/* "$snapshot_dir/" 2>/dev/null || true
    
    print_success "Snapshot created at: $snapshot_dir"
    log "Snapshot created: $snapshot_dir"
}

synchronize_backups() {
    print_header "Synchronizing Backups"
    
    print_progress "Scanning for changes..."
    
    # Use rsync if available for incremental sync
    if command -v rsync &> /dev/null; then
        rsync -avz --delete "$SYSTEM_FILES_DIR/" "$BACKUP_DIR/latest/" 2>&1 | tee -a "$TRANSFER_LOG"
        print_success "Backups synchronized"
    else
        print_info "rsync not available, performing full copy..."
        cp -rp "$SYSTEM_FILES_DIR/" "$BACKUP_DIR/latest/"
        print_success "Backups synchronized"
    fi
    
    log "Backup synchronization completed"
}

#############################################
# Backup Statistics
#############################################

show_backup_stats() {
    print_header "Backup Statistics"
    
    echo ""
    print_info "Backup Directory Size:"
    du -sh "$BACKUP_DIR" | awk '{print "  Total: " $1}'
    
    echo ""
    print_info "Backup Breakdown:"
    du -sh "$BACKUP_DIR"/* | awk '{print "  " $2 ": " $1}'
    
    echo ""
    print_info "Number of Backups:"
    backup_count=$(find "$BACKUP_DIR" -maxdepth 1 -type d | wc -l)
    echo "  $((backup_count - 1)) backup(s) found"
    
    echo ""
    print_info "Last Backup:"
    latest=$(ls -t "$BACKUP_DIR" | head -n1)
    echo "  $latest"
    
    echo ""
    log "Showed backup statistics"
}

#############################################
# Cleanup
#############################################

cleanup_old_backups() {
    local retention_days="${1:-30}"
    
    print_header "Cleaning Up Old Backups"
    print_progress "Removing backups older than $retention_days days..."
    
    find "$BACKUP_DIR" -maxdepth 1 -type d -mtime "+$retention_days" -exec rm -rf {} + 2>&1 | tee -a "$TRANSFER_LOG"
    
    print_success "Old backups cleaned up (retention: $retention_days days)"
    log "Cleaned up backups older than $retention_days days"
}

#############################################
# Help & Usage
#############################################

show_help() {
    cat << EOF
${BLUE}WebConnect Data Transfer Module${NC}

${GREEN}Usage:${NC}
  transfer.sh [COMMAND] [OPTIONS]

${GREEN}Commands:${NC}
  
  ${BLUE}Transfer Operations:${NC}
    transfer-local <source> <destination>
      Transfer backup to local destination
      
    transfer-sftp <source> <host> <path>
      Transfer backup via SFTP
      
    transfer-http <source> <endpoint>
      Upload backup to HTTP endpoint
  
  ${BLUE}Backup Management:${NC}
    list-backups
      List all available backups
      
    create-snapshot
      Create a new system snapshot
      
    restore <backup-name> [destination]
      Restore from a specific backup
      
    sync-backups
      Synchronize all backups
      
    stats
      Show backup statistics
      
    cleanup [retention-days]
      Remove backups older than specified days (default: 30)
  
  ${BLUE}Encryption:${NC}
    encrypt <source> <output>
      Encrypt a backup file
      
    decrypt <source> <output>
      Decrypt a backup file
  
  ${BLUE}Utility:${NC}
    help
      Show this help message
      
    version
      Show version information

${GREEN}Examples:${NC}
  # List available backups
  ./transfer.sh list-backups
  
  # Transfer backup locally
  ./transfer.sh transfer-local ~/.webconnect/backup/20260226_120000 /mnt/backup/
  
  # Encrypt a backup
  ./transfer.sh encrypt ~/.webconnect/backup/20260226_120000 ./backup.encrypted
  
  # Restore from backup
  ./transfer.sh restore 20260226_120000 /path/to/restore
  
  # Show statistics
  ./transfer.sh stats

${GREEN}More Information:${NC}
  Documentation: https://automast.github.io/webconnect
  Config File: $CONFIG_FILE
  Log File: $TRANSFER_LOG

EOF
}

show_version() {
    echo "WebConnect Data Transfer Module v1.0.0"
    echo "© 2026 - All rights reserved"
}

#############################################
# Main Command Handler
#############################################

main() {
    local command="${1:-help}"
    
    case "$command" in
        transfer-local)
            transfer_local "$2" "$3"
            ;;
        transfer-sftp)
            transfer_sftp "$2" "$3" "$4"
            ;;
        transfer-http)
            transfer_http "$2" "$3"
            ;;
        list-backups|ls)
            list_backups
            ;;
        create-snapshot|snapshot)
            create_snapshot
            ;;
        restore)
            restore_from_backup "$2" "${3:-.}"
            ;;
        sync|sync-backups)
            synchronize_backups
            ;;
        encrypt)
            encrypt_backup "$2" "$3"
            ;;
        decrypt)
            decrypt_backup "$2" "$3"
            ;;
        stats|statistics)
            show_backup_stats
            ;;
        cleanup)
            cleanup_old_backups "${2:-30}"
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version)
            show_version
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use 'transfer.sh help' for usage information"
            exit 1
            ;;
    esac
}

# Initialize log file
mkdir -p "$(dirname "$TRANSFER_LOG")"
touch "$TRANSFER_LOG"

# Run main handler
main "$@"
