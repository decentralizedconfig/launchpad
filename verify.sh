#!/bin/bash

#############################################
# WebConnect Installation Verification
# Validates installation and environment
# Version: 1.0.0
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation directory
INSTALL_DIR="${HOME}/.webconnect"

# Results tracking
PASSED=0
FAILED=0
WARNINGS=0

#############################################
# Test Functions
#############################################

print_test() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARNINGS++))
}

#############################################
# Directory Structure Tests
#############################################

test_directories() {
    print_test "Directory Structure"
    
    local dirs=(
        "$INSTALL_DIR"
        "$INSTALL_DIR/software"
        "$INSTALL_DIR/system_files"
        "$INSTALL_DIR/backup"
        "$INSTALL_DIR/logs"
        "$INSTALL_DIR/config"
    )
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            pass "Directory exists: $dir"
        else
            fail "Directory missing: $dir"
        fi
    done
}

#############################################
# File Tests
#############################################

test_files() {
    print_test "Required Files"
    
    local files=(
        "$INSTALL_DIR/config.json"
        "$INSTALL_DIR/install.log"
        "$INSTALL_DIR/uninstall.sh"
        "$INSTALL_DIR/transfer.sh"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            if [ -x "$file" ] 2>/dev/null && [[ "$file" == *.sh ]]; then
                pass "File exists and executable: $file"
            elif [[ "$file" == *.json ]] || [[ "$file" == *.log ]]; then
                pass "File exists: $file"
            fi
        else
            fail "File missing: $file"
        fi
    done
}

#############################################
# Configuration Tests
#############################################

test_configuration() {
    print_test "Configuration Validity"
    
    if [ ! -f "$INSTALL_DIR/config.json" ]; then
        fail "config.json not found"
        return 1
    fi
    
    # Test if valid JSON
    if command -v jq &> /dev/null; then
        if jq . "$INSTALL_DIR/config.json" > /dev/null 2>&1; then
            pass "config.json is valid JSON"
            
            # Check for required fields
            local version=$(jq -r '.version' "$INSTALL_DIR/config.json" 2>/dev/null)
            if [ -n "$version" ]; then
                pass "Configuration has version: $version"
            else
                fail "Configuration missing version field"
            fi
        else
            fail "config.json is invalid JSON"
        fi
    else
        warn "jq not available - skipping JSON validation"
    fi
}

#############################################
# Dependency Tests
#############################################

test_dependencies() {
    print_test "Required Dependencies"
    
    local required_cmds=("bash" "curl" "git")
    
    for cmd in "${required_cmds[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>&1 | head -n1)
            pass "Dependency available: $cmd"
        else
            fail "Dependency missing: $cmd"
        fi
    done
    
    # Optional dependencies
    local optional_cmds=("jq" "openssl" "rsync" "scp")
    
    for cmd in "${optional_cmds[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            pass "Optional dependency available: $cmd"
        else
            warn "Optional dependency missing: $cmd"
        fi
    done
}

#############################################
# OS Detection Test
#############################################

test_os_detection() {
    print_test "Operating System Detection"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pass "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            pass "Detected Windows (WSL)"
        else
            pass "Detected Linux"
        fi
    else
        fail "Unable to detect operating system"
    fi
}

#############################################
# Backup Tests
#############################################

test_backups() {
    print_test "Backup Integrity"
    
    if [ ! -d "$INSTALL_DIR/backup" ]; then
        warn "No backups found - this is normal for fresh installation"
        return
    fi
    
    local backup_count=$(find "$INSTALL_DIR/backup" -maxdepth 1 -type d | wc -l)
    
    if [ $backup_count -gt 1 ]; then
        pass "Found $((backup_count - 1)) backup(s)"
    else
        warn "No backups found in backup directory"
    fi
}

#############################################
# Log Tests
#############################################

test_logs() {
    print_test "Logging System"
    
    if [ -f "$INSTALL_DIR/logs/install.log" ]; then
        pass "Installation log exists"
        
        local entries=$(wc -l < "$INSTALL_DIR/logs/install.log")
        pass "Log entries found: $entries"
    else
        fail "Installation log not found"
    fi
}

#############################################
# Script Functionality Tests
#############################################

test_transfer_script() {
    print_test "Data Transfer Script"
    
    if [ ! -f "$INSTALL_DIR/transfer.sh" ]; then
        fail "transfer.sh not found"
        return
    fi
    
    if [ ! -x "$INSTALL_DIR/transfer.sh" ]; then
        fail "transfer.sh is not executable"
        return
    fi
    
    pass "transfer.sh exists and is executable"
    
    # Test help function
    if "$INSTALL_DIR/transfer.sh" help > /dev/null 2>&1; then
        pass "transfer.sh help command works"
    else
        fail "transfer.sh help command failed"
    fi
}

#############################################
# Uninstall Script Test
#############################################

test_uninstall_script() {
    print_test "Uninstall Script"
    
    if [ ! -f "$INSTALL_DIR/uninstall.sh" ]; then
        fail "uninstall.sh not found"
        return
    fi
    
    if [ ! -x "$INSTALL_DIR/uninstall.sh" ]; then
        fail "uninstall.sh is not executable"
        return
    fi
    
    pass "uninstall.sh exists and is executable"
}

#############################################
# PATH Configuration Test
#############################################

test_path_configuration() {
    print_test "PATH Configuration"
    
    local shell_config=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        shell_config="$HOME/.zshrc"
    else
        shell_config="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_config" ]; then
        if grep -q "\.webconnect" "$shell_config" 2>/dev/null; then
            pass "WebConnect added to PATH in $shell_config"
        else
            warn "WebConnect not found in PATH - may need to run 'source $shell_config'"
        fi
    else
        warn "Shell configuration file not found: $shell_config"
    fi
}

#############################################
# Permissions Test
#############################################

test_permissions() {
    print_test "File Permissions"
    
    # Check if we can write to install directory
    if [ -w "$INSTALL_DIR" ]; then
        pass "Write permission to $INSTALL_DIR"
    else
        fail "No write permission to $INSTALL_DIR"
    fi
    
    # Check system files directory
    if [ -d "$INSTALL_DIR/system_files" ] && [ -r "$INSTALL_DIR/system_files" ]; then
        pass "Read permission to system_files directory"
    else
        warn "Limited read permission to system_files directory"
    fi
}

#############################################
# Network Tests
#############################################

test_network() {
    print_test "Network Connectivity"
    
    print "Testing connection to GitHub..."
    if curl -s -o /dev/null -w "%{http_code}" https://github.com > /dev/null 2>&1; then
        pass "GitHub connectivity OK"
    else
        warn "GitHub connectivity issues - may affect updates"
    fi
    
    print "Testing connection to repository..."
    if curl -s -o /dev/null -w "%{http_code}" https://automast.github.io/webconnect > /dev/null 2>&1; then
        pass "Repository connectivity OK"
    else
        warn "Repository connectivity issues"
    fi
}

#############################################
# Summary & Report
#############################################

print_summary() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Passed:${NC}  $PASSED"
    echo -e "${RED}Failed:${NC}  $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All critical tests passed!${NC}"
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠ $WARNINGS warning(s) - review above for details${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Some tests failed - review above for details${NC}"
        return 1
    fi
}

#############################################
# Main Test Runner
#############################################

run_all_tests() {
    clear
    
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  WebConnect Installation Verification ║${NC}"
    echo -e "${BLUE}║         Version 1.0.0              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
    
    # Run all tests
    test_directories
    test_files
    test_configuration
    test_dependencies
    test_os_detection
    test_backups
    test_logs
    test_transfer_script
    test_uninstall_script
    test_path_configuration
    test_permissions
    test_network
    
    # Print summary
    print_summary
}

#############################################
# Entry Point
#############################################

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}WebConnect installation not found at: $INSTALL_DIR${NC}"
    echo "Please run the installation script first:"
    echo "  curl -fsSL https://automast.github.io/webconnect/secure.sh | bash"
    exit 1
fi

# Run verification
run_all_tests
exit $?
