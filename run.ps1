# MediaBox Run Script for Windows PowerShell
# Run this to start the Docker container

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Starting MediaBox Container" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if image exists
$imageExists = docker images | Select-String "mediabox"
if (-not $imageExists) {
    Write-Host "MediaBox image not found. Building..." -ForegroundColor Yellow
    .\build.ps1
    if ($LASTEXITCODE -ne 0) {
        exit 1
    }
}

# Check if container is already running
$containerRunning = docker ps | Select-String "mediabox-controller"
if ($containerRunning) {
    Write-Host "Container is already running" -ForegroundColor Yellow
    Write-Host ""
    docker ps | Select-String "mediabox-controller"
    Write-Host ""
    Write-Host "To restart: docker-compose restart" -ForegroundColor Cyan
    Write-Host "To stop: docker-compose down" -ForegroundColor Cyan
    exit 0
}

Write-Host "Starting MediaBox services..." -ForegroundColor Green
Write-Host ""

# Start with docker-compose
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "[OK] MediaBox Started Successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Wait for services to be ready
    Write-Host "Waiting for services to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Show container status
    docker-compose ps
    
    Write-Host ""
    Write-Host "Access Points:" -ForegroundColor Yellow
    Write-Host "  • Dashboard:      http://localhost:8080" -ForegroundColor Cyan
    Write-Host "  • Home Assistant: http://localhost:8123" -ForegroundColor Cyan
    Write-Host "  • API Docs:       http://localhost:8080/api/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Useful Commands:" -ForegroundColor Yellow
    Write-Host "  • View logs:      docker-compose logs -f" -ForegroundColor White
    Write-Host "  • Stop services:  docker-compose down" -ForegroundColor White
    Write-Host "  • Restart:        docker-compose restart" -ForegroundColor White
    Write-Host "  • Shell access:   docker exec -it mediabox-controller bash" -ForegroundColor White
    Write-Host ""
    Write-Host "Health Check:" -ForegroundColor Yellow
    Write-Host "  curl http://localhost:8080/api/health" -ForegroundColor White
    Write-Host ""
    
    # Try to open dashboard in browser
    Write-Host "Opening dashboard in browser..." -ForegroundColor Green
    Start-Process "http://localhost:8080"
} else {
    Write-Host "[ERROR] Failed to start container" -ForegroundColor Red
    exit 1
}

