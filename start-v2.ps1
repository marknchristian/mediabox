# MediaBox AI V2 - Startup Script for Windows
# Starts the Electron app with V2-specific backend services

# Fix PATH to include Node.js (Windows PowerShell Unicode fix)
chcp 65001 > $null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI V2 - Starting Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load V2 configuration
Write-Host "[1/3] Loading V2 configuration..." -ForegroundColor Yellow
Get-Content v2-config.env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}
Write-Host "[OK] Configuration loaded" -ForegroundColor Green
Write-Host "  - Dashboard API: Port $env:PORT" -ForegroundColor Gray
Write-Host "  - Voice Control: Port $env:VOICE_PORT" -ForegroundColor Gray
Write-Host ""

# Check if Node.js and npm are available
Write-Host "[2/4] Checking Node.js and npm..." -ForegroundColor Yellow
# Refresh PATH to include Node.js
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue

if (-not $nodeCmd) {
    Write-Host "[ERROR] Node.js not found!" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org" -ForegroundColor Yellow
    exit 1
}
if (-not $npmCmd) {
    Write-Host "[ERROR] npm not found!" -ForegroundColor Red
    Write-Host "Please reinstall Node.js to include npm" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Node.js found: $($nodeCmd.Version)" -ForegroundColor Green
Write-Host "[OK] npm found: $($npmCmd.Version)" -ForegroundColor Green
Write-Host ""

# Check if Python is available
Write-Host "[3/4] Checking Python..." -ForegroundColor Yellow
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    Write-Host "Please install Python 3.11+ from https://python.org" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Python found: $($pythonCmd.Version)" -ForegroundColor Green
Write-Host ""

# Start backend services
Write-Host "[4/4] Starting backend services..." -ForegroundColor Yellow
Write-Host "  - Starting Dashboard API on port $env:PORT..." -ForegroundColor Gray

# Start Dashboard API in background
Start-Process python -ArgumentList "scripts/dashboard-api.py" -WindowStyle Hidden

# Wait a moment for services to start
Start-Sleep -Seconds 2

Write-Host "[OK] Backend services started" -ForegroundColor Green
Write-Host ""

# Start Electron app
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Electron Desktop App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  - Electron App: Starting..." -ForegroundColor Gray
Write-Host "  - Dashboard API: http://localhost:$env:PORT" -ForegroundColor Gray
Write-Host "  - Voice Control: http://localhost:$env:VOICE_PORT" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

# Start Electron with proper npm path
Write-Host "Starting Electron app..." -ForegroundColor Green
try {
    # Use cmd to run npm to avoid PowerShell parsing issues
    cmd /c "npm run dev"
} catch {
    Write-Host "[ERROR] Failed to start Electron app!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Fallback: try direct npm path
    $npmPath = "C:\Program Files\nodejs\npm.cmd"
    if (Test-Path $npmPath) {
        Write-Host "Using npm from: $npmPath" -ForegroundColor Gray
        cmd /c "`"$npmPath`" run dev"
    } else {
        Write-Host "[ERROR] Could not find npm. Please check Node.js installation." -ForegroundColor Red
        exit 1
    }
}

