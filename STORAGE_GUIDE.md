# WebConnect Storage Configuration Guide

## Overview

WebConnect includes comprehensive storage management for handling **large system file transfers** across multiple storage destinations. The system supports local, network, and cloud storage options.

## Storage Architecture

```
Duplicated System Files
          ↓
Local Internal Storage (~/.webconnect/backup/)
          ↓
    ┌─────┼─────┬────────┬──────────┐
    ↓     ↓     ↓        ↓          ↓
External SMB   SFTP   AWS S3   Azure Blob
Drive   Share  Server Storage  Storage
```

## Storage Configuration Files

### 1. `storage.config.json`
Main configuration file defining all available storage destinations and policies.

**Key Sections:**
- **destinations** - Available storage options with priorities
- **transfer_settings** - Compression, encryption, chunking
- **storage_management** - Retention, deduplication, cleanup
- **bandwidth** - Transfer rate limits
- **scheduling** - Automated sync timing
- **monitoring** - Disk space alerts

### 2. Files Transferred To Storage

After installation, these system files are duplicated to configured storage:

**macOS:**
```
~/.ssh/config
~/.ssh/authorized_keys
~/.zshrc
~/.bash_profile
```

**Linux/WSL:**
```
~/.ssh/config
~/.ssh/authorized_keys
~/.bashrc
/etc/hostname
```

## Storage Destinations

### 1. **Internal Storage** (Default)
```json
{
  "name": "internal",
  "type": "local",
  "path": "~/.webconnect/backup",
  "quota_gb": 50,
  "priority": 1
}
```

**Use When:**
- Quick local backups
- Testing transfers
- Small file sets

**Size Considerations:**
- Max 50GB (default)
- Configurable quota
- Auto-cleanup available

---

### 2. **External Drive**
```json
{
  "name": "external_drive",
  "type": "local",
  "path": "/mnt/backup",
  "quota_gb": 500,
  "priority": 2,
  "auto_detect": true
}
```

**Setup:**
```bash
# Detect external drives
./storage-manager.sh detect-drives

# Configure external storage
./storage-manager.sh configure-external
```

**Use When:**
- Large file backups (100GB+)
- Offline storage
- Disaster recovery

**Size Considerations:**
- Typical USB drives: 64GB - 256GB
- External hard drives: 1TB - 10TB+
- Configurable quota per destination

---

### 3. **SMB Network Share**
```json
{
  "name": "network_share",
  "type": "smb",
  "host": "192.168.1.100",
  "share": "backups",
  "path": "/mnt/backup",
  "quota_gb": 1000,
  "priority": 3
}
```

**Setup:**
```bash
./storage-manager.sh configure-smb
```

**Use When:**
- NAS storage (Synology, QNAP, etc.)
- Windows network shares
- Large corporate backups (500GB+)

**Size Considerations:**
- NAS capacity: 2TB - 100TB+
- Network speed matters
- Supports quota limits

---

### 4. **SFTP Remote Server**
```json
{
  "name": "sftp_server",
  "type": "sftp",
  "host": "backup.example.com",
  "port": 22,
  "key_file": "~/.ssh/id_rsa",
  "path": "/backups/webconnect",
  "quota_gb": 2000,
  "priority": 4
}
```

**Setup:**
```bash
./storage-manager.sh configure-sftp
```

**Use When:**
- VPS/dedicated servers
- Remote backup servers
- Secure encrypted transfers
- Medium-large backups (100GB - 2TB)

**Size Considerations:**
- Server disk space: varies
- Network bandwidth: 1Mbps+
- Supports incremental backups

---

### 5. **AWS S3**
```json
{
  "name": "aws_s3",
  "type": "cloud_s3",
  "bucket": "my-webconnect-backups",
  "region": "us-east-1",
  "storage_class": "STANDARD_IA",
  "quota_gb": 5000,
  "priority": 5
}
```

**Setup:**
```bash
./storage-manager.sh configure-s3

# Or use AWS CLI
aws s3 mb s3://my-webconnect-backups
aws s3api put-bucket-versioning --bucket my-webconnect-backups --versioning-configuration Status=Enabled
```

**Storage Classes:**
- **STANDARD**: $0.023/GB/month - Frequent access
- **STANDARD_IA**: $0.0125/GB/month - Infrequent access
- **GLACIER**: $0.004/GB/month - Archive
- **DEEP_ARCHIVE**: $0.00099/GB/month - Long-term archive

**Cost Estimate for 1TB:**
```
STANDARD_IA: ~$12/month
One-time transfer: ~$100 (out of AWS region)
Operations: ~$1-5/month
```

**Use When:**
- Unlimited storage needs
- Global access requirements
- Disaster recovery (multiple regions)
- Large backups (1TB+)

---

### 6. **Microsoft Azure Blob Storage**
```json
{
  "name": "azure_blob",
  "type": "cloud_azure",
  "account_name": "mystorageaccount",
  "container": "webconnect-backups",
  "quota_gb": 5000,
  "priority": 6
}
```

**Setup:**
```bash
# Create storage account and container
az storage account create --name mystorageaccount --resource-group mygroup
az storage container create --account-name mystorageaccount --name webconnect-backups
```

**Tiers:**
- **Hot**: $0.0184/GB/month
- **Cool**: $0.01/GB/month
- **Archive**: $0.002/GB/month

---

### 7. **Google Cloud Storage**
```json
{
  "name": "google_cloud",
  "type": "cloud_gcs",
  "bucket": "my-webconnect-backups",
  "credentials_file": "~/.webconnect/config/gcs-credentials.json",
  "quota_gb": 5000,
  "priority": 7
}
```

**Storage Classes:**
- **STANDARD**: $0.020/GB/month
- **NEARLINE**: $0.010/GB/month
- **COLDLINE**: $0.004/GB/month
- **ARCHIVE**: $0.0012/GB/month

---

### 8. **Dropbox**
```json
{
  "name": "dropbox",
  "type": "cloud_dropbox",
  "path": "/WebConnect/Backups",
  "quota_gb": 2000,
  "priority": 8
}
```

**Plans:**
- Basic: 2GB free
- Plus: 2TB - $9.99/month
- Family: 2TB (up to 6 users) - $15.99/month

---

### 9. **Google Drive**
```json
{
  "name": "google_drive",
  "type": "cloud_drive",
  "folder_id": "your-folder-id",
  "quota_gb": 2000,
  "priority": 9
}
```

**Plans:**
- Free: 15GB
- 100GB: $1.99/month
- 200GB: $2.99/month
- 2TB: $9.99/month

---

## Transfer Settings

### Compression
```json
"compression": {
  "enabled": true,
  "algorithm": "gzip",
  "level": 6,
  "min_file_size_mb": 10
}
```

**Compression Ratios (typical):**
- Config files: 70-80% reduction
- Text files: 60-80% reduction
- Binaries: 10-30% reduction
- Already compressed (zip, jpg): 0-5% reduction

---

### Chunking for Large Files
```json
"transfer_settings": {
  "chunk_size_mb": 10,
  "max_file_size_gb": 5,
  "parallel_transfers": 4
}
```

**Chunk Size Benefits:**
- Smaller chunks: Better resume support, lower memory
- Larger chunks: Faster transfers
- Recommended: 10MB for most systems

---

### Encryption
```json
"encryption": {
  "enabled": true,
  "algorithm": "AES-256",
  "key_derivation": "PBKDF2"
}
```

✅ Enabled by default for all transfers

---

## Storage Management

### Retention Policy
```json
"retention_policy": {
  "retention_days": 3,       # Keep daily backups
  "archive_days": 90,        # Archive older backups
  "delete_days": 365         # Delete after 1 year
}
```

### Incremental Backups
```json
"incremental_backups": {
  "enabled": true,
  "changed_files_only": true,
  "differential_backup": true
}
```

**Benefits:**
- 60-80% size reduction
- Faster transfers
- Reduced storage costs

### Deduplication
```json
"deduplication": {
  "enabled": true,
  "algorithm": "sha256",
  "local_dedup": true,
  "cloud_dedup": false
}
```

---

## Usage Examples

### 1. **Local External Drive (USB 256GB)**
```bash
# Detect drive
./storage-manager.sh detect-drives

# Configure
./storage-manager.sh configure-external

# Transfer
~/.webconnect/transfer.sh transfer-local ~/.webconnect/backup/latest /mnt/usb-drive/
```

**Capacity:** 256GB
**Transfer Time:** 10-30 minutes
**Cost:** One-time device cost

---

### 2. **NAS Storage (Synology 4TB)**
```bash
# Configure SMB
./storage-manager.sh configure-smb

# Mount NAS
sudo mount -t cifs //nas-ip/backups /mnt/nas -o username=user,password=pass

# Transfer
~/.webconnect/transfer.sh transfer-local ~/.webconnect/backup /mnt/nas/webconnect
```

**Capacity:** 4TB
**Transfer Time:** 1-3 hours
**Cost:** $200-500 one-time

---

### 3. **AWS S3 (Unlimited Scalability)**
```bash
# Configure S3
./storage-manager.sh configure-s3

# Transfer
~/.webconnect/transfer.sh transfer-http ~/.webconnect/backup s3://bucket/backup

# Restore
aws s3 cp s3://bucket/backup/archive.tar.gz . --sse-kms-key-id your-key
```

**Capacity:** Unlimited
**Monthly Cost:** $12-50 for typical backups
**Transfer Time:** Depends on bandwidth

---

## Monitoring & Alerts

### Disk Space Threshold
```json
"monitoring": {
  "disk_space_threshold_percent": 80,
  "alert_on_low_space": true,
  "pause_on_critical": 95
}
```

### Check Storage Status
```bash
./storage-manager.sh status
./storage-manager.sh analyze
```

### Automatic Cleanup
```json
"storage_management": {
  "auto_cleanup": true,
  "cleanup_interval_days": 7
}
```

---

## Troubleshooting

### Large File Transfer Issues
```bash
# Reduce chunk size
jq '.storage.transfer_settings.chunk_size_mb = 5' storage.config.json

# Enable compression
jq '.storage.transfer_settings.compression.enabled = true' storage.config.json
```

### Storage Full
```bash
# Cleanup old backups
./storage-manager.sh cleanup 3

# Analyze usage
./storage-manager.sh analyze

# Enable deduplication
jq '.storage.storage_management.deduplication.enabled = true' storage.config.json
```

### Network Issues
```bash
# Enable retry with backoff
jq '.storage.transfer_settings.retry.enabled = true' storage.config.json
jq '.storage.transfer_settings.retry.attempts = 5' storage.config.json

# Add delay between retries
jq '.storage.transfer_settings.retry.delay_seconds = 10' storage.config.json
```

---

## Capacity Planning

### Typical System File Sizes
```
SSH keys + config:        50-100 KB
Shell configs (.bashrc):  10-50 KB
.config directory:        100MB-5GB
/etc/hosts:              < 1 KB
Total typical:           100MB-5GB
```

### Recommended Storage by Use Case

| Use Case | Storage Type | Size | Cost |
|----------|--------------|------|------|
| Single user | External USB | 256GB | $30-50 |
| Small business | NAS | 2-4TB | $200-500 |
| Medium business | SFTP Server | 5-10TB | VPS cost |
| Enterprise | AWS S3 | Unlimited | $50+/month |
| Archive | S3 Glacier | Unlimited | $5/month |

---

## Best Practices

1. **Enable Compression** - Reduces file size by 60-80%
2. **Use Incremental Backups** - Only backup changed files
3. **Enable Encryption** - Protect sensitive data
4. **Multiple Destinations** - At least 2 backup locations
5. **Regular Cleanup** - Remove old backups monthly
6. **Monitor Space** - Set alerts at 80% capacity
7. **Test Restores** - Verify backups can be restored
8. **Schedule Syncs** - Automate regular transfers

---

## Support

For issues with storage configuration:
```bash
# View logs
tail -f ~/.webconnect/logs/storage.log

# Run diagnostic
./storage-manager.sh status
./storage-manager.sh analyze

# Check configuration
cat ~/.webconnect/config/storage.config.json
```

---

**Last Updated:** February 26, 2026
