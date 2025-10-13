#!/bin/bash
# MediaBox AI Dashboard Startup Script
# Starts Flask API and optionally launches browser dashboard

set -e

echo "=================================================="
echo "   MediaBox AI Dashboard - Starting Services"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine if we're in Docker or native
IN_DOCKER=false
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    IN_DOCKER=true
fi

# Set paths based on environment
if [ "$IN_DOCKER" = true ]; then
    APP_DIR="/app"
    SCRIPTS_DIR="/app/scripts"
    DASHBOARD_DIR="/app/dashboard"
else
    APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    SCRIPTS_DIR="$APP_DIR/scripts"
    DASHBOARD_DIR="$APP_DIR/dashboard"
fi

echo -e "${GREEN}Environment:${NC} $([ "$IN_DOCKER" = true ] && echo "Docker Container" || echo "Native")"
echo -e "${GREEN}App Directory:${NC} $APP_DIR"
echo ""

# Function to check if port is in use
check_port() {
    local port=$1
    if command -v netstat &> /dev/null; then
        netstat -tuln | grep -q ":$port "
    elif command -v ss &> /dev/null; then
        ss -tuln | grep -q ":$port "
    else
        # Fallback: try to connect
        timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null
    fi
    return $?
}

# Start Flask API Server
echo -e "${YELLOW}[1/4] Starting Flask API Server...${NC}"
cd "$SCRIPTS_DIR"

if check_port 8080; then
    echo -e "${YELLOW}   ⚠ Port 8080 already in use${NC}"
    echo -e "   Dashboard API may already be running"
else
    export PORT=8080
    python3 "$SCRIPTS_DIR/dashboard-api.py" > /var/log/flask-api.log 2>&1 &
    FLASK_PID=$!
    echo -e "${GREEN}   ✓ Flask API started (PID: $FLASK_PID)${NC}"
    
    # Wait for Flask to be ready
    echo -n "   Waiting for API to be ready"
    for i in {1..10}; do
        if check_port 8080; then
            echo -e " ${GREEN}✓${NC}"
            break
        fi
        echo -n "."
        sleep 1
    done
fi

# Check Home Assistant
echo -e "${YELLOW}[2/4] Checking Home Assistant...${NC}"
if check_port 8123; then
    echo -e "${GREEN}   ✓ Home Assistant is running${NC}"
else
    echo -e "${YELLOW}   ⚠ Home Assistant not detected${NC}"
    echo "   It should be started by supervisor in Docker"
    echo "   Or install separately: pip install homeassistant"
fi

# Check PulseAudio
echo -e "${YELLOW}[3/4] Checking Audio System...${NC}"
if command -v pactl &> /dev/null; then
    if pactl info &> /dev/null; then
        echo -e "${GREEN}   ✓ PulseAudio is running${NC}"
    else
        echo -e "${YELLOW}   ⚠ PulseAudio not responding${NC}"
        echo "   Starting PulseAudio..."
        pulseaudio --start --log-target=syslog 2>/dev/null || true
    fi
else
    echo -e "${RED}   ✗ PulseAudio not installed${NC}"
fi

# Launch Dashboard UI (only if not in Docker or if DISPLAY is set)
echo -e "${YELLOW}[4/4] Dashboard UI...${NC}"

if [ -z "$DISPLAY" ]; then
    echo -e "${YELLOW}   ⚠ No DISPLAY set, skipping browser launch${NC}"
    echo "   Access dashboard at: http://localhost:8080"
else
    if command -v chromium-browser &> /dev/null; then
        CHROMIUM_CMD="chromium-browser"
    elif command -v chromium &> /dev/null; then
        CHROMIUM_CMD="chromium"
    elif command -v google-chrome &> /dev/null; then
        CHROMIUM_CMD="google-chrome"
    else
        echo -e "${YELLOW}   ⚠ No browser found${NC}"
        echo "   Access dashboard at: http://localhost:8080"
        CHROMIUM_CMD=""
    fi
    
    if [ -n "$CHROMIUM_CMD" ]; then
        echo -e "${GREEN}   ✓ Launching browser dashboard...${NC}"
        
        # Launch in kiosk mode for full-screen experience
        $CHROMIUM_CMD \
            --kiosk \
            --disable-infobars \
            --disable-session-crashed-bubble \
            --disable-restore-session-state \
            --app=http://localhost:8080 \
            > /dev/null 2>&1 &
        
        BROWSER_PID=$!
        echo -e "${GREEN}   ✓ Browser launched (PID: $BROWSER_PID)${NC}"
    fi
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✓ MediaBox AI Dashboard Started Successfully!${NC}"
echo "=================================================="
echo ""
echo "Access Points:"
echo "  • Dashboard:        http://localhost:8080"
echo "  • API Endpoints:    http://localhost:8080/api/"
echo "  • Home Assistant:   http://localhost:8123"
echo "  • Voice Control:    http://localhost:8081/voice/api/"
echo ""
echo "API Health Check:"
echo "  curl http://localhost:8080/api/health"
echo ""
echo "Logs:"
echo "  • Flask API: /var/log/flask-api.log"
echo "  • Supervisor: /var/log/supervisor/"
echo ""

if [ "$IN_DOCKER" = false ]; then
    echo "To stop services:"
    echo "  kill $FLASK_PID"
    [ -n "$BROWSER_PID" ] && echo "  kill $BROWSER_PID"
    echo ""
    
    # Keep script running if browser was launched
    if [ -n "$BROWSER_PID" ]; then
        echo "Press Ctrl+C to stop all services"
        trap "kill $FLASK_PID $BROWSER_PID 2>/dev/null; exit" INT TERM
        wait $BROWSER_PID
        kill $FLASK_PID 2>/dev/null
    fi
else
    echo "Running in Docker - services managed by supervisor"
    echo "=================================================="
fi
