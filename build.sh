#!/bin/bash
# Build script for MediaBox Docker image

set -e

echo "============================================"
echo "  Building MediaBox Docker Container"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}Warning: Docker Compose not found${NC}"
    echo "Attempting to build with docker build only..."
    BUILD_ONLY=true
fi

echo -e "${GREEN}[1/3] Preparing build environment...${NC}"

# Create necessary directories
mkdir -p ha_config
mkdir -p scripts
mkdir -p dashboard

echo -e "${GREEN}[2/3] Building Docker image...${NC}"
echo ""

# Build the image
docker build -t mediabox:latest .

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Docker image built successfully!${NC}"
    echo ""
else
    echo -e "${RED}✗ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}[3/3] Checking build...${NC}"

# Show image info
docker images | grep mediabox

echo ""
echo "============================================"
echo -e "${GREEN}✓ Build Complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Start the container:"
echo "     docker-compose up -d"
echo ""
echo "  2. View logs:"
echo "     docker-compose logs -f"
echo ""
echo "  3. Access services:"
echo "     • Dashboard: http://localhost:8080"
echo "     • Home Assistant: http://localhost:8123"
echo ""
echo "  4. Enter container:"
echo "     docker exec -it mediabox-controller bash"
echo ""

