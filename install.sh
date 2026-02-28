#!/bin/bash
###############################################
# WebConnect Wallet Backup - Universal Installer
# Works on Mac, Linux, and Windows (WSL/MSYS)
# Detects OS and downloads appropriate backup script
###############################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/yourusername/wallet-backup"
INSTALL_DIR="${HOME}/.webconnect"
CONFIG_FILE="${INSTALL_DIR}/config/storage.config.json"
BACKUP_DIR="${INSTALL_DIR}/wallet_backups"
LOG_DIR="${INSTALL_DIR}/logs"

# Detect OS
detect_os() {
    case "$OSTYPE" in
        darwin*)
            echo "macos"
            ;;
        linux*)
            echo "linux"
            ;;
        msys*|mingw*|cygwin*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Print with color
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Create directories
setup_directories() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "${INSTALL_DIR}/config"
    chmod 700 "$INSTALL_DIR"
    print_success "Directories created"
}

# Download configuration if not exists
setup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_info "Downloading configuration..."
        if command -v curl &> /dev/null; then
            curl -fsSL "${REPO_URL}/raw/main/config.template.json" -o "$CONFIG_FILE" || {
                print_error "Failed to download config"
                return 1
            }
        elif command -v wget &> /dev/null; then
            wget -q -O "$CONFIG_FILE" "${REPO_URL}/raw/main/config.template.json" || {
                print_error "Failed to download config"
                return 1
            }
        else
            print_error "curl or wget required"
            return 1
        fi
        chmod 600 "$CONFIG_FILE"
        print_success "Configuration created at $CONFIG_FILE"
        print_warning "Please edit the file and add your Dropbox token"
    else
        print_info "Configuration already exists"
    fi
}

# Download and run backup script
run_backup() {
    local os=$(detect_os)
    local script_url
    local script_name
    
    case "$os" in
        macos|linux)
            script_name="backup.sh"
            script_url="${REPO_URL}/raw/main/${script_name}"
            print_info "Detected: macOS/Linux"
            
            # Download and execute
            if command -v curl &> /dev/null; then
                bash <(curl -fsSL "$script_url")
            elif command -v wget &> /dev/null; then
                bash <(wget -q -O - "$script_url")
            else
                print_error "curl or wget required"
                return 1
            fi
            ;;
        windows)
            print_error "Windows detected - please run PowerShell version instead:"
            echo ""
            echo "  powershell -Command \"& {Invoke-WebRequest -Uri '${REPO_URL}/raw/main/backup-wallet.ps1' -OutFile backup-wallet.ps1; .\\backup-wallet.ps1}\""
            echo ""
            return 1
            ;;
        *)
            print_error "Unknown OS: $os"
            return 1
            ;;
    esac
}

# Main
main() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  WebConnect Wallet Backup Installer${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    
    setup_directories
    setup_config
    
    print_info "Starting backup..."
    echo ""
    
    run_backup
}

# Execute
main "$@"
