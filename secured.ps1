#############################################
# WebConnect Wallet Backup - Universal Installer
# Works on Windows PowerShell 5.1+
# Downloads and runs appropriate backup script
#############################################

param(
    [switch]$Force
)

# Colors and output
function Write-InfoMsg {
    Write-Host "[INFO] $args" -ForegroundColor Blue
}

function Write-SuccessMsg {
    Write-Host "[OK] $args" -ForegroundColor Green
}

function Write-ErrorMsg {
    Write-Host "[ERROR] $args" -ForegroundColor Red
}

function Write-WarningMsg {
    Write-Host "[WARN] $args" -ForegroundColor Yellow
}

# Configuration
$RepoUrl = "https://github.com/yourusername/wallet-backup"
$InstallDir = "$env:USERPROFILE\.webconnect"
$ConfigFile = "$InstallDir\config\storage.config.json"
$BackupDir = "$InstallDir\wallet_backups"
$LogDir = "$InstallDir\logs"

# Create directories
function Setup-Directories {
    # Clean up existing directories to avoid permission issues
    if (Test-Path $InstallDir) {
        try {
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-InfoMsg "Cleaned up existing installation directory"
        }
        catch {
            Write-WarningMsg "Could not remove existing directory: $_"
        }
    }
    
    # Create fresh directories
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$InstallDir\config" -Force | Out-Null
    
    # Restrict permissions on install dir (best-effort)
    try {
        $Acl = Get-Acl $InstallDir
        $Acl.SetAccessRuleProtection($true, $false)
        Set-Acl -Path $InstallDir -AclObject $Acl
    }
    catch {
        Write-WarningMsg "Could not set ACL (continuing anyway): $_"
    }
    
    Write-SuccessMsg "Directories created"
}

# Download configuration
function Setup-Configuration {
    if ((Test-Path $ConfigFile) -and -not $Force) {
        Write-InfoMsg "Configuration already exists"
        return
    }
    
    Write-InfoMsg "Downloading configuration..."
    
    try {
        $configUrl = "$RepoUrl/raw/main/config.template.json"
        Invoke-WebRequest -Uri $configUrl -OutFile $ConfigFile -ErrorAction Stop
        
        # Restrict permissions
        $Acl = Get-Acl $ConfigFile
        $Acl.SetAccessRuleProtection($true, $false)
        Set-Acl -Path $ConfigFile -AclObject $Acl
        
        Write-SuccessMsg "Configuration created at $ConfigFile"
        Write-SuccessMsg "Configuration ready (Google Drive integration enabled)"
    }
    catch {
        Write-ErrorMsg "Failed to download config: $_"
        return $false
    }
    
    return $true
}

# Download and run backup script
function Run-Backup {
    Write-InfoMsg "Downloading backup script..."
    
    $scriptUrl = "$RepoUrl/raw/main/decentralized.ps1"
    $tempScript = "$env:TEMP\decentralized-temp.ps1"
    
    try {
        Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScript -ErrorAction Stop
        
        Write-InfoMsg "Starting backup..."
        Write-Host ""
        
        # Execute the downloaded script
        & $tempScript
        
        # Cleanup
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-ErrorMsg "Failed to download or execute backup script: $_"
        return $false
    }
    
    return $true
}

# Main
function Main {
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host "  WebConnect Wallet Backup Installer" -ForegroundColor Blue
    Write-Host "================================================" -ForegroundColor Blue
    Write-Host ""
    
    Setup-Directories
    
    if (-not (Setup-Configuration)) {
        Write-ErrorMsg "Failed to setup configuration"
        exit 1
    }
    
    Write-Host ""
    if (-not (Run-Backup)) {
        Write-ErrorMsg "Backup failed"
        exit 1
    }
    
    Write-SuccessMsg "Complete!"
}

# Execute
Main
