# MediaBox Build Script for Windows PowerShell
# Run this to build the Docker container

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Building MediaBox Docker Container" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed" -ForegroundColor Red
    Write-Host "Please install Docker Desktop: https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
try {
    docker ps | Out-Null
} catch {
    Write-Host "Error: Docker is not running" -ForegroundColor Red
    Write-Host "Please start Docker Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/3] Preparing build environment..." -ForegroundColor Green

# Create necessary directories
if (-not (Test-Path "ha_config")) {
    New-Item -ItemType Directory -Path "ha_config" | Out-Null
}
if (-not (Test-Path "scripts")) {
    New-Item -ItemType Directory -Path "scripts" | Out-Null
}
if (-not (Test-Path "dashboard")) {
    New-Item -ItemType Directory -Path "dashboard" | Out-Null
}

Write-Host "[2/3] Building Docker image..." -ForegroundColor Green
Write-Host ""

# Build the image
docker build -t mediabox:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Docker image built successfully!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "✗ Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "[3/3] Checking build..." -ForegroundColor Green

# Show image info
docker images | Select-String "mediabox"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "✓ Build Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start the container:" -ForegroundColor White
Write-Host "     docker-compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. View logs:" -ForegroundColor White
Write-Host "     docker-compose logs -f" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Access services:" -ForegroundColor White
Write-Host "     • Dashboard: http://localhost:8080" -ForegroundColor Cyan
Write-Host "     • Home Assistant: http://localhost:8123" -ForegroundColor Cyan
Write-Host ""
Write-Host "  4. Enter container:" -ForegroundColor White
Write-Host "     docker exec -it mediabox-controller bash" -ForegroundColor Cyan
Write-Host ""

