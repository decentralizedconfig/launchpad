# Google Drive Setup Guide

WebConnect now backs up wallet data to **Google Drive** — no special accounts needed, just your own secure folder.

## Quick Setup (3 Steps)

### 1. Get Your Google Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or use existing
3. Search for **"Service Accounts"** → Click **Create Service Account**
4. Name: `webconnect-backup`
5. Click **Create** → **Create Key** → **JSON**
6. A JSON file downloads — keep it safe

### 2. Share Your Google Drive Folder

1. In Google Drive, create/select your backup folder
2. Click **Share** → paste the email from the JSON (looks like `webconnect-backup@....iam.gserviceaccount.com`)
3. Give it **Editor** permission
4. Get your folder ID from the URL: `https://drive.google.com/drive/folders/[FOLDER_ID_HERE]`

### 3. Create Local Config

1. Run the backup script once: `.\backup-wallet.ps1`
2. It auto-creates `C:\Users\<yourname>\.webconnect\config\storage.config.json`
3. Edit that file and replace placeholders:
   - `YOUR_GOOGLE_DRIVE_FOLDER_ID` → your folder ID
   - Copy entire `credentials` object from your JSON file

Example:
```json
{
  "storage": {
    "destinations": [
      {
        "name": "google_drive",
        "type": "google_drive",
        "enabled": true,
        "folder_id": "1F9EDEuDwNfFtUWlppIOFfO4yEoKc9Je7",
        "credentials": {
          "type": "service_account",
          "project_id": "my-project-123",
          "private_key": "-----BEGIN PRIVATE KEY-----\n...",
          ...
        }
      }
    ]
  }
}
```

## Thats it!

Now when you run `.\backup-wallet.ps1`:
1. Choose backup type (phrase/private key/keystore)
2. Paste your data
3. Backup saves **locally** + uploads to **Google Drive** automatically

**Important**: Keep `storage.config.json` private on your machine. Never share it or commit it to git.
