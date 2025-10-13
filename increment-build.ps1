# Increment Build Number
# Run this after making changes to dashboard

$buildFile = "dashboard\build.txt"

# Read current build number
if (Test-Path $buildFile) {
    $currentBuild = [int](Get-Content $buildFile)
} else {
    $currentBuild = 0
}

# Increment
$newBuild = $currentBuild + 1

# Save new build number
$newBuild | Out-File -FilePath $buildFile -NoNewline -Encoding ASCII

Write-Host "[OK] Build number incremented: $currentBuild -> $newBuild" -ForegroundColor Green

# Restart Docker to apply changes
Write-Host "Restarting MediaBox container..." -ForegroundColor Cyan
docker-compose restart mediabox

Write-Host "`nBuild $newBuild is now live!" -ForegroundColor Green
Write-Host "Hard refresh browser: Ctrl + Shift + R`n" -ForegroundColor Yellow

