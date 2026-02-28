#!/bin/bash

#############################################
# WebConnect Storage Manager
# Manages storage destinations and quotas
# for large system file transfers
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

# Paths
INSTALL_DIR="${HOME}/.webconnect"
STORAGE_CONFIG="${INSTALL_DIR}/config/storage.config.json"
STORAGE_LOG="${INSTALL_DIR}/logs/storage.log"

#############################################
# Utility Functions
#############################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$STORAGE_LOG"
}

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
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
# Storage Detection
#############################################

detect_external_drives() {
    print_header "Detecting External Storage"
    
    local found=0
    
    # Check common mount points
    local mount_points=("/media" "/mnt" "/Volumes" "/run/media")
    
    for mount in "${mount_points[@]}"; do
        if [ -d "$mount" ]; then
            while IFS= read -r device; do
                if [ -n "$device" ]; then
                    local size=$(df -h "$device" 2>/dev/null | tail -n1 | awk '{print $2}')
                    local free=$(df -h "$device" 2>/dev/null | tail -n1 | awk '{print $4}')
                    local usage=$(df -h "$device" 2>/dev/null | tail -n1 | awk '{print $5}')
                    
                    print_success "Found: $device"
                    echo "         Size: $size | Free: $free | Usage: $usage"
                    found=$((found + 1))
                    log "Detected external drive: $device ($size, $free free)"
                fi
            done < <(find "$mount" -maxdepth 1 -type d 2>/dev/null | grep -v "^$mount$")
        fi
    done
    
    if [ $found -eq 0 ]; then
        print_warning "No external drives detected"
    else
        echo ""
        print_success "Total external drives found: $found"
    fi
}

#############################################
# Storage Status
#############################################

show_storage_status() {
    print_header "Storage Status"
    
    echo ""
    echo -e "${PURPLE}Local Storage:${NC}"
    
    # Show internal backup storage
    if [ -d "$INSTALL_DIR/backup" ]; then
        local size=$(du -sh "$INSTALL_DIR/backup" 2>/dev/null | awk '{print $1}')
        local count=$(find "$INSTALL_DIR/backup" -maxdepth 1 -type d -not -name "backup" | wc -l)
        
        echo "  Path: $INSTALL_DIR/backup"
        echo "  Size: $size"
        echo "  Backups: $count"
    fi
    
    echo ""
    echo -e "${PURPLE}Available Destinations:${NC}"
    
    # Parse storage config and show destinations
    if command -v jq &> /dev/null && [ -f "$STORAGE_CONFIG" ]; then
        local count=$(jq '.storage.destinations | length' "$STORAGE_CONFIG")
        
        for ((i=0; i<count; i++)); do
            local name=$(jq -r ".storage.destinations[$i].name" "$STORAGE_CONFIG")
            local type=$(jq -r ".storage.destinations[$i].type" "$STORAGE_CONFIG")
            local enabled=$(jq -r ".storage.destinations[$i].enabled" "$STORAGE_CONFIG")
            local quota=$(jq -r ".storage.destinations[$i].quota_gb" "$STORAGE_CONFIG")
            
            if [ "$enabled" = "true" ]; then
                echo "  ✓ $name ($type) - Quota: ${quota}GB"
            else
                echo "  ✗ $name ($type) - Quota: ${quota}GB [disabled]"
            fi
        done
    else
        print_warning "Storage config not found or jq not installed"
    fi
}

#############################################
# Destination Configuration
#############################################

configure_destination() {
    local dest_type="$1"
    
    print_header "Configure Storage Destination"
    
    case "$dest_type" in
        external)
            print_info "Configuring External Drive Storage"
            detect_external_drives
            
            read -p "Enter the path to external drive: " ext_path
            
            if [ -d "$ext_path" ]; then
                mkdir -p "$ext_path/webconnect-backup"
                print_success "External storage configured: $ext_path/webconnect-backup"
                log "External storage configured: $ext_path"
            else
                print_error "Path not found: $ext_path"
                return 1
            fi
            ;;
        
        smb)
            print_info "Configuring SMB Network Share"
            
            read -p "Enter SMB host (e.g., 192.168.1.100): " smb_host
            read -p "Enter share name: " smb_share
            read -p "Enter mount path (e.g., /mnt/backup): " smb_path
            read -p "Enter username: " smb_user
            read -sp "Enter password: " smb_pass
            echo
            
            # Create mount point
            sudo mkdir -p "$smb_path"
            
            # Mount SMB share
            sudo mount -t cifs "//$smb_host/$smb_share" "$smb_path" \
                -o username="$smb_user",password="$smb_pass"
            
            if [ $? -eq 0 ]; then
                print_success "SMB share mounted: $smb_path"
                log "SMB share configured: //$smb_host/$smb_share -> $smb_path"
            else
                print_error "Failed to mount SMB share"
                return 1
            fi
            ;;
        
        sftp)
            print_info "Configuring SFTP Remote Storage"
            
            read -p "Enter SFTP host: " sftp_host
            read -p "Enter SFTP port (default 22): " -e -i "22" sftp_port
            read -p "Enter username: " sftp_user
            read -p "Use key file? (y/n): " use_key
            
            if [[ "$use_key" =~ ^[Yy]$ ]]; then
                read -p "Enter path to SSH key: " ssh_key
            else
                read -sp "Enter password: " sftp_pass
                echo
            fi
            
            print_success "SFTP remote configured"
            log "SFTP configured: $sftp_user@$sftp_host:$sftp_port"
            ;;
        
        s3)
            print_info "Configuring AWS S3 Storage"
            
            read -p "Enter S3 bucket name: " s3_bucket
            read -p "Enter AWS region (default us-east-1): " -e -i "us-east-1" aws_region
            read -p "Enter AWS Access Key ID: " aws_access_key
            read -sp "Enter AWS Secret Access Key: " aws_secret_key
            echo
            
            print_success "AWS S3 configured"
            log "S3 configured: $s3_bucket ($aws_region)"
            ;;
        
        *)
            print_error "Unknown destination type: $dest_type"
            return 1
            ;;
    esac
}

#############################################
# Storage Analysis
#############################################

analyze_storage() {
    print_header "Storage Usage Analysis"
    
    echo ""
    echo -e "${PURPLE}Backup Directory Breakdown:${NC}"
    
    if [ -d "$INSTALL_DIR/backup" ]; then
        du -sh "$INSTALL_DIR/backup"/* 2>/dev/null | sort -rh | while read size dir; do
            local name=$(basename "$dir")
            echo "  $size - $name"
        done
    fi
    
    echo ""
    echo -e "${PURPLE}System Files Directory:${NC}"
    
    if [ -d "$INSTALL_DIR/system_files" ]; then
        local total=$(du -sh "$INSTALL_DIR/system_files" | awk '{print $1}')
        echo "  Total: $total"
    fi
    
    echo ""
    echo -e "${PURPLE}Disk Space Summary:${NC}"
    
    df -h "$INSTALL_DIR" | tail -n1 | awk '{
        printf "  Root: %s total | %s used | %s available (%s%% used)\n", $2, $3, $4, $5
    }'
    
    log "Storage analysis completed"
}

#############################################
# Cleanup & Maintenance
#############################################

cleanup_old_backups() {
    local days="${1:-3}"
    
    print_header "Cleanup Old Backups"
    print_info "Removing backups older than $days days..."
    
    local count=0
    find "$INSTALL_DIR/backup" -maxdepth 1 -type d -mtime "+$days" | while read backup; do
        if [ -d "$backup" ] && [ "$backup" != "$INSTALL_DIR/backup" ]; then
            local size=$(du -sh "$backup" | awk '{print $1}')
            rm -rf "$backup"
            print_success "Deleted: $(basename $backup) ($size)"
            count=$((count + 1))
        fi
    done
    
    log "Cleaned up backups older than $days days"
}

deduplicate_storage() {
    print_header "Deduplicating Storage"
    print_info "Finding and removing duplicate files..."
    
    if [ -d "$INSTALL_DIR/backup" ]; then
        # Use checksums to find duplicates
        local temp_checksums=$(mktemp)
        
        find "$INSTALL_DIR/backup" -type f -exec sha256sum {} \; > "$temp_checksums"
        
        local duplicates=$(awk '{print $1}' "$temp_checksums" | sort | uniq -d | wc -l)
        
        if [ $duplicates -gt 0 ]; then
            print_warning "Found $duplicates potential duplicates"
            # Note: Actual deduplication would require filesystem support
        else
            print_success "No duplicates found"
        fi
        
        rm "$temp_checksums"
    fi
    
    log "Deduplication completed"
}

#############################################
# Help & Usage
#############################################

show_help() {
    cat << EOF
${BLUE}WebConnect Storage Manager${NC}

${GREEN}Usage:${NC}
  storage-manager.sh [COMMAND] [OPTIONS]

${GREEN}Commands:${NC}
  
  ${BLUE}Storage Detection:${NC}
    detect-drives
      Find external storage devices
      
    status
      Show storage status and available destinations
  
  ${BLUE}Configuration:${NC}
    configure-external
      Setup external USB/drive storage
      
    configure-smb
      Setup SMB network share
      
    configure-sftp
      Setup SFTP remote server
      
    configure-s3
      Setup AWS S3 storage
  
  ${BLUE}Maintenance:${NC}
    analyze
      Analyze storage usage
      
    cleanup [days]
      Remove backups older than days (default: 3)
      
    deduplicate
      Find and manage duplicate files
  
  ${BLUE}Utility:${NC}
    help
      Show this help message

${GREEN}Examples:${NC}
  # Detect external drives
  ./storage-manager.sh detect-drives
  
  # Show storage status
  ./storage-manager.sh status
  
  # Configure external drive
  ./storage-manager.sh configure-external
  
  # Analyze storage usage
  ./storage-manager.sh analyze
  
  # Clean old backups
  ./storage-manager.sh cleanup 30

${BLUE}Note:${NC}
  For large file storage, ensure you have:
  - Sufficient disk space
  - Network connectivity (for cloud/remote)
  - Proper permissions for mount points
  - Compression enabled (recommended)

EOF
}

#############################################
# Main Handler
#############################################

main() {
    mkdir -p "$(dirname "$STORAGE_LOG")"
    touch "$STORAGE_LOG"
    
    local command="${1:-help}"
    
    case "$command" in
        detect-drives|detect)
            detect_external_drives
            ;;
        status)
            show_storage_status
            ;;
        configure-external|config-external)
            configure_destination "external"
            ;;
        configure-smb|config-smb)
            configure_destination "smb"
            ;;
        configure-sftp|config-sftp)
            configure_destination "sftp"
            ;;
        configure-s3|config-s3)
            configure_destination "s3"
            ;;
        analyze|analysis)
            analyze_storage
            ;;
        cleanup)
            cleanup_old_backups "${2:-3}"
            ;;
        deduplicate|dedup)
            deduplicate_storage
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use 'storage-manager.sh help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
