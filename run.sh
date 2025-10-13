#!/bin/bash
# Run script for MediaBox Docker container

set -e

echo "============================================"
echo "  Starting MediaBox Container"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if image exists
if ! docker images | grep -q "mediabox"; then
    echo -e "${YELLOW}MediaBox image not found. Building...${NC}"
    ./build.sh
fi

# Check if container is already running
if docker ps | grep -q "mediabox-controller"; then
    echo -e "${YELLOW}Container is already running${NC}"
    echo ""
    docker ps | grep mediabox-controller
    echo ""
    echo "To restart: docker-compose restart"
    echo "To stop: docker-compose down"
    exit 0
fi

echo -e "${GREEN}Starting MediaBox services...${NC}"
echo ""

# Start with docker-compose
docker-compose up -d

if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo -e "${GREEN}✓ MediaBox Started Successfully!${NC}"
    echo "============================================"
    echo ""
    
    # Wait for services to be ready
    echo "Waiting for services to start..."
    sleep 5
    
    # Show container status
    docker-compose ps
    
    echo ""
    echo "Access Points:"
    echo "  • Dashboard:      http://localhost:8080"
    echo "  • Home Assistant: http://localhost:8123"
    echo "  • API Docs:       http://localhost:8080/api/"
    echo ""
    echo "Useful Commands:"
    echo "  • View logs:      docker-compose logs -f"
    echo "  • Stop services:  docker-compose down"
    echo "  • Restart:        docker-compose restart"
    echo "  • Shell access:   docker exec -it mediabox-controller bash"
    echo ""
    echo "Health Check:"
    echo "  curl http://localhost:8080/api/health"
    echo ""
else
    echo -e "${RED}✗ Failed to start container${NC}"
    exit 1
fi

