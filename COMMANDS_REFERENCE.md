# Wallet Backup Commands Reference

## Windows

### Option 1: Double-click the batch file
```
decentralized.bat
```
*(Easiest - just double-click the file in Windows Explorer)*

### Option 2: PowerShell command
```powershell
.\decentralized.ps1
```

### Option 3: Full PowerShell path
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\holly\My Command Mac\decentralized.ps1"
```

### Option 4: Alternative - one-liner
```powershell
cd "C:\Users\holly\My Command Mac" ; .\decentralized.ps1
```

---

## macOS/Linux

### Direct execution
```bash
./backup-wallet.sh
```

### With full path
```bash
bash /path/to/My\ Command\ Mac/backup-wallet.sh
```

### Make it executable first (if needed)
```bash
chmod +x backup-wallet.sh
./backup-wallet.sh
```

---

## Creating a Desktop Shortcut (Windows)

### Using Batch File
1. Right-click `decentralized.bat`
2. Select "Send to" → "Desktop (create shortcut)"
3. Done! Double-click the shortcut to backup

### Manual Shortcut
1. Right-click on Desktop → "New" → "Shortcut"
2. Location: `C:\Users\holly\My Command Mac\decentralized.bat`
3. Name: "Wallet Backup" (or your preference)
4. Click Finish

---

## Adding to PowerShell Profile

To make `backup-wallet` a command you can run from anywhere:

### 1. Open PowerShell as Administrator
```powershell
Start-Process powershell -Verb RunAs
```

### 2. Edit your profile
```powershell
notepad $PROFILE
```

### 3. Add this line
```powershell
function backup-wallet { & "C:\Users\holly\My Command Mac\decentralized.ps1" }
```

### 4. Save and restart PowerShell

### Now you can type anywhere:
```powershell
backup-wallet
```

---

## Automating Daily Backups (Windows Task Scheduler)

### Via PowerShell (Recommended)

```powershell
# Create a scheduled task to run backup daily at 2 AM
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Users\holly\My Command Mac\decentralized.ps1`"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "WebConnect Wallet Backup" -Action $taskAction -Trigger $trigger -RunLevel Highest
```

### Via GUI
1. Open Tasks Scheduler (search for "Task Scheduler")
2. Click "Create Basic Task"
3. Name: "WebConnect Wallet Backup"
4. Trigger: Daily at 2:00 AM
5. Action: Start a program
6. Program: `powershell.exe`
7. Arguments: `-NoProfile -ExecutionPolicy Bypass -File "C:\Users\holly\My Command Mac\decentralized.ps1"`

---

## Verify Backups Exist

### Check Local Backups
```powershell
dir "$env:USERPROFILE\.webconnect\wallet_backups\"
```

### Check Log File
```powershell
cat "$env:USERPROFILE\.webconnect\logs\backup.log" | tail -20
```

---

## Troubleshooting Commands

### If PowerShell scripts won't run
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run the script again
.\decentralized.ps1
```

### Test if Dropbox connection works
```powershell
# Check if curl is available
curl.exe --version

# Or test directly in PowerShell
Invoke-WebRequest -Uri "https://api.dropboxapi.com/2/check/user" -Headers @{Authorization="Bearer YOUR_TOKEN"} -Method Post
```

### View encryption success
```powershell
# List all encrypted backups
Get-ChildItem "$env:USERPROFILE\.webconnect\wallet_backups\" -Filter "*.enc"

# Check file sizes
Get-ChildItem "$env:USERPROFILE\.webconnect\wallet_backups\" -Filter "*.enc" | Format-Table Name, Length
```

---

## File Locations

```
Windows:
  Script:       C:\Users\holly\My Command Mac\decentralized.ps1
  Launcher:     C:\Users\holly\My Command Mac\decentralized.bat
  Local backups: %USERPROFILE%\.webconnect\wallet_backups\
  Logs:         %USERPROFILE%\.webconnect\logs\backup.log
  Config:       %USERPROFILE%\.webconnect\config\storage.config.json

macOS/Linux:
  Script:       ~/My Command Mac/backup-wallet.sh
  Local backups: ~/.webconnect/wallet_backups/
  Logs:         ~/.webconnect/logs/backup.log
  Config:       ~/.webconnect/config/storage.config.json

Dropbox Cloud:
  Path: /WebConnect/Wallet_Backups/
    ├── recovery_phrases/
    ├── private_keys/
    └── keystores/
```

---

## Quick Copy-Paste Commands

### Current Directory (fastest)
**Windows:**
```
.\decentralized.ps1
```

**macOS/Linux:**
```
./backup-wallet.sh
```

### Check backups created
**Windows:**
```powershell
Get-ChildItem "$env:USERPROFILE\.webconnect\wallet_backups" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

**macOS/Linux:**
```bash
ls -lth ~/.webconnect/wallet_backups | head -10
```

---

## Environment Setup Complete! ✓

Your wallet backup system is configured and ready to use.

**Next Step:** Run the backup script:
```
.\decentralized.ps1
```

Choose option 1️⃣, 2️⃣, or 3️⃣ from the menu, and your data will be encrypted and backed up to Dropbox!

---

*Last Updated: February 27, 2026*
