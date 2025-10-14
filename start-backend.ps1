# MediaBox AI V2 - Backend Only Startup Script
# Starts the Python backend API service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI V2 - Starting Backend" -ForegroundColor Cyan
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

# Start backend service
Write-Host "[3/3] Starting backend services..." -ForegroundColor Yellow
Write-Host "  - Starting Dashboard API on port $env:PORT..." -ForegroundColor Gray

# Start Dashboard API
Start-Process python -ArgumentList "scripts/dashboard-api.py" -WindowStyle Normal

# Wait a moment for services to start
Start-Sleep -Seconds 2

Write-Host "[OK] Backend services started" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend Services Running" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  - Dashboard API: http://localhost:$env:PORT" -ForegroundColor Gray
Write-Host "  - Network Access: http://192.168.0.232:$env:PORT" -ForegroundColor Gray
Write-Host "  - Health Check: http://localhost:$env:PORT/api/health" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to stop the service..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

