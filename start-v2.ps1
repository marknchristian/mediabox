# MediaBox AI V2 - Startup Script for Windows
# Starts the Electron app with V2-specific backend services

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

# Check if Python is available
Write-Host "[2/3] Checking Python..." -ForegroundColor Yellow
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "[ERROR] Python not found!" -ForegroundColor Red
    Write-Host "Please install Python 3.11+ from https://python.org" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Python found: $($pythonCmd.Version)" -ForegroundColor Green
Write-Host ""

# Start backend services
Write-Host "[3/3] Starting backend services..." -ForegroundColor Yellow
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

# Start Electron
npm run dev

