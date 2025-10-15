# Widevine CDM Installation Script for Electron
# This script copies Widevine files from Chrome to Electron

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Widevine CDM Installation for Electron" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Chrome or Edge Widevine exists
$chromeWidevinePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\WidevineCdm"
$edgeWidevinePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\WidevineCdm"

$widevinePath = $null
$browserName = ""

if (Test-Path $chromeWidevinePath) {
    $widevinePath = $chromeWidevinePath
    $browserName = "Chrome"
    Write-Host "[OK] Chrome Widevine folder found" -ForegroundColor Green
} elseif (Test-Path $edgeWidevinePath) {
    $widevinePath = $edgeWidevinePath
    $browserName = "Edge"
    Write-Host "[OK] Edge Widevine folder found" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Widevine folder not found in Chrome or Edge!" -ForegroundColor Red
    Write-Host "Please open Edge and go to: edge://components/" -ForegroundColor Yellow
    Write-Host "Then click 'Check for update' on Widevine Content Decryption Module" -ForegroundColor Yellow
    exit 1
}

# Step 2: Find the version folder
Write-Host "[DEBUG] Checking contents of: $widevinePath" -ForegroundColor Cyan
$allItems = Get-ChildItem $widevinePath
Write-Host "[DEBUG] Found items:" -ForegroundColor Cyan
$allItems | ForEach-Object { Write-Host "  - $($_.Name) ($($_.Mode))" -ForegroundColor Gray }

$versionFolders = Get-ChildItem $widevinePath -Directory

if ($versionFolders.Count -eq 0) {
    Write-Host "[ERROR] No Widevine version found!" -ForegroundColor Red
    Write-Host "The WidevineCdm folder exists but contains no version directories." -ForegroundColor Yellow
    Write-Host "Please open $browserName and go to: chrome://components/" -ForegroundColor Yellow
    Write-Host "Then click 'Check for update' on Widevine Content Decryption Module" -ForegroundColor Yellow
    Write-Host "Wait for it to download completely, then run this script again." -ForegroundColor Yellow
    exit 1
}

$versionFolder = $versionFolders[0].FullName
Write-Host "[OK] Found Widevine version: $($versionFolders[0].Name)" -ForegroundColor Green

# Step 3: Find the DLL files
$dllPath = Join-Path $versionFolder "_platform_specific\win_x64"

if (-not (Test-Path $dllPath)) {
    Write-Host "[ERROR] Widevine DLL files not found at: $dllPath" -ForegroundColor Red
    Write-Host "Please open $browserName and go to: edge://components/" -ForegroundColor Yellow
    Write-Host "Then click 'Check for update' on Widevine Content Decryption Module" -ForegroundColor Yellow
    exit 1
}

$widevineDll = Join-Path $dllPath "widevinecdm.dll"
$adapterDll = Join-Path $dllPath "widevinecdmadapter.dll"

if (-not (Test-Path $widevineDll)) {
    Write-Host "[ERROR] widevinecdm.dll not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $adapterDll)) {
    Write-Host "[ERROR] widevinecdmadapter.dll not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found Widevine DLL files" -ForegroundColor Green

# Step 4: Create widevine folder in project
$projectWidevinePath = Join-Path $PSScriptRoot "widevine"

if (-not (Test-Path $projectWidevinePath)) {
    New-Item -ItemType Directory -Path $projectWidevinePath | Out-Null
    Write-Host "[OK] Created widevine folder" -ForegroundColor Green
}

# Step 5: Copy DLL files
$destWidevineDll = Join-Path $projectWidevinePath "widevinecdm.dll"
$destAdapterDll = Join-Path $projectWidevinePath "widevinecdmadapter.dll"

Copy-Item $widevineDll $destWidevineDll -Force
Copy-Item $adapterDll $destAdapterDll -Force

Write-Host "[OK] Copied Widevine DLL files to project" -ForegroundColor Green

# Step 6: Get version number
$version = $versionFolders[0].Name

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Widevine version: $version" -ForegroundColor Yellow
Write-Host "Files copied to: $projectWidevinePath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Update main.js with Widevine path" -ForegroundColor White
Write-Host "2. Restart Electron app" -ForegroundColor White
Write-Host "3. Test Netflix" -ForegroundColor White
Write-Host ""

