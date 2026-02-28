# WebConnect Interactive Wallet Backup - Quick Start

## 🚀 How to Backup Your Wallet

### **Windows (Easiest Way)**

Simply double-click:
```
backup-wallet.bat
```

Or in PowerShell terminal:
```powershell
.\backup-wallet.ps1
```

### **macOS/Linux**

In your terminal:
```bash
./backup-wallet.sh
```

---

## 📋 What You Can Backup

### 1️⃣ **Recovery Phrase**
- Your 12 or 24-word seed phrase
- Used to recover your wallet if lost
- **Input by:** Pasting the words

### 2️⃣ **Private Key**
- Your wallet's private key (0x...)
- Gives full control of your wallet
- **Input by:** Pasting the hex key (input is hidden)

### 3️⃣ **Keystore JSON & Password**
- Backup of your wallet configuration
- JSON file + password combination
- **Input by:** Pasting JSON, then entering password (both hidden)

---

## 🔒 Security Details

✅ **All data is encrypted before uploading**
- Uses AES-256 encryption
- Encrypted locally first
- Only encrypted data goes to Dropbox

✅ **Your inputs are never logged**
- Password inputs are hidden (*)
- Private key inputs are hidden (*)
- Only filenames are logged

✅ **Backups stored securely**
- Local backup: `~/.webconnect/wallet_backups/`
- Online backup: Dropbox `/WebConnect/Wallet_Backups/`
- File permissions: 600 (owner only)

---

## ⚙️ Configuration

### Prerequisites
- **Windows**: PowerShell (included with Windows)
- **macOS/Linux**: Bash shell
- **Network**: Internet connection (for Dropbox upload)

### Dropbox Setup
Your Dropbox token is already configured in:
```
~/.webconnect/config/storage.config.json
```

If not configured:
1. Generate a Dropbox access token from https://www.dropbox.com/developers/apps
2. Update the `access_token` field in the config file
3. Run the backup script again

---

## 📝 Typical Workflow

### **Scenario 1: Backup Recovery Phrase**

```
1. Run: .\backup-wallet.ps1

2. See menu:
   Select option (1-4): 1

3. Paste your phrase:
   Paste your recovery phrase: chase combine trust around cloud ...

4. Automatic backup:
   ✓ Phrase encrypted locally
   ✓ Uploaded to Dropbox
   ✓ Backup Complete!
```

### **Scenario 2: Backup Private Key**

```
1. Run: .\backup-wallet.ps1

2. See menu:
   Select option (1-4): 2

3. Paste your private key (hidden):
   Paste your private key: ••••••••••••••••••••••••••...

4. Automatic backup:
   ✓ Key encrypted locally
   ✓ Uploaded to Dropbox
   ✓ Backup Complete!
```

### **Scenario 3: Backup Keystore**

```
1. Run: .\backup-wallet.ps1

2. See menu:
   Select option (1-4): 3

3. Paste JSON (hidden):
   Paste your Keystore JSON: {"version": 3, "id": "...

4. Enter password (hidden):
   Enter your Keystore password: ••••••••••

5. Automatic backup:
   ✓ Keystore encrypted locally
   ✓ Uploaded to Dropbox
   ✓ Backup Complete!
```

---

## 🎯 Key Points

| Item | Details |
|------|---------|
| **Encryption** | AES-256 (before upload) |
| **Storage** | Dropbox + Local (~/.webconnect/) |
| **Speed** | 1-2 minutes per backup |
| **File Format** | .enc (encrypted) |
| **Privacy** | No passwords logged |
| **Backup Size** | Usually < 1 MB per file |

---

## ❓ Troubleshooting

### Script won't run?
```powershell
# Allow PowerShell scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run
.\backup-wallet.ps1
```

### Dropbox upload fails?
- Check your internet connection
- Verify Dropbox token in `~/.webconnect/config/storage.config.json`
- Local backup still saves even if upload fails

### Can't find the backups?
- Local: Open `%USERPROFILE%\.webconnect\wallet_backups\`
- Online: Check your Dropbox `/WebConnect/Wallet_Backups/`

---

## 🛡️ Best Practices

1. **Regular Backups**: Backup your keys regularly (weekly or monthly)
2. **Multiple Locations**: Backups are saved locally AND to Dropbox
3. **Secure Inputs**: This script never displays or logs your sensitive data
4. **Verify Offline**: Keep a handwritten copy of your recovery phrase in a safe location
5. **Test Restoration**: Occasionally test that your backups work

---

## 📞 Support

For issues or questions:
- Check WALLET_BACKUP_GUIDE.md for detailed docs
- Review logs: `~/.webconnect/logs/backup.log`
- Verify Dropbox credentials in storage.config.json

---

**Last Updated:** February 27, 2026  
**Version:** 1.0.0
