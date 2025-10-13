#!/bin/bash
# MediaBox AI Server-Side Test Suite
# Tests that run inside the Docker container

set -e

CONTAINER_NAME="mediabox-controller"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

passed=0
failed=0
warnings=0

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      MediaBox AI Server-Side Test Suite                          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper function for test results
test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        ((passed++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠ WARN${NC} - $test_name"
        ((warnings++))
    else
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        ((failed++))
    fi
    
    if [ -n "$message" ]; then
        echo -e "       $message"
    fi
}

echo -e "${BLUE}=== Container Health Tests ===${NC}\n"

# Test 1: Container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
    test_result "Test 1: Container is running" "pass" "Container status: Running"
else
    test_result "Test 1: Container is running" "fail" "Container not found or not running"
    exit 1
fi

# Test 2: Supervisor is running
if docker exec "$CONTAINER_NAME" pgrep supervisord > /dev/null; then
    test_result "Test 2: Supervisor process is running" "pass"
else
    test_result "Test 2: Supervisor process is running" "fail"
fi

echo -e "\n${BLUE}=== Service Status Tests ===${NC}\n"

# Test 3: PulseAudio service
if docker exec "$CONTAINER_NAME" supervisorctl status pulseaudio 2>/dev/null | grep -q "RUNNING"; then
    test_result "Test 3: PulseAudio service is running" "pass"
else
    test_result "Test 3: PulseAudio service is running" "warn" "May not be needed on all systems"
fi

# Test 4: Xvfb service
if docker exec "$CONTAINER_NAME" supervisorctl status xvfb 2>/dev/null | grep -q "RUNNING"; then
    test_result "Test 4: Xvfb (Virtual Display) is running" "pass"
else
    test_result "Test 4: Xvfb (Virtual Display) is running" "fail"
fi

# Test 5: Flask API service
if docker exec "$CONTAINER_NAME" supervisorctl status flask-api 2>/dev/null | grep -q "RUNNING"; then
    test_result "Test 5: Flask API service is running" "pass"
else
    test_result "Test 5: Flask API service is running" "fail"
fi

# Test 6: Home Assistant service
if docker exec "$CONTAINER_NAME" supervisorctl status homeassistant 2>/dev/null | grep -q "RUNNING"; then
    test_result "Test 6: Home Assistant service is running" "pass"
else
    test_result "Test 6: Home Assistant service is running" "warn" "May still be starting up"
fi

echo -e "\n${BLUE}=== Network & Port Tests ===${NC}\n"

# Test 7: Port 8080 is listening
if docker exec "$CONTAINER_NAME" netstat -tuln 2>/dev/null | grep -q ":8080"; then
    test_result "Test 7: Flask is listening on port 8080" "pass"
else
    test_result "Test 7: Flask is listening on port 8080" "fail"
fi

# Test 8: Port 8123 is listening (Home Assistant)
sleep 2  # Give HA a moment to start
if docker exec "$CONTAINER_NAME" netstat -tuln 2>/dev/null | grep -q ":8123"; then
    test_result "Test 8: Home Assistant is listening on port 8123" "pass"
else
    test_result "Test 8: Home Assistant is listening on port 8123" "warn" "May still be initializing"
fi

echo -e "\n${BLUE}=== File System Tests ===${NC}\n"

# Test 9: Dashboard files exist
if docker exec "$CONTAINER_NAME" test -f /app/dashboard/index.html; then
    test_result "Test 9: Dashboard HTML file exists" "pass"
else
    test_result "Test 9: Dashboard HTML file exists" "fail"
fi

# Test 10: Script files exist and are executable
scripts_ok=true
for script in dashboard-api.py audio-switcher.py iptv-launcher.py voice-control-api.py; do
    if ! docker exec "$CONTAINER_NAME" test -x "/app/scripts/$script"; then
        scripts_ok=false
        break
    fi
done

if [ "$scripts_ok" = true ]; then
    test_result "Test 10: All script files are executable" "pass"
else
    test_result "Test 10: All script files are executable" "fail"
fi

# Test 11: Log files exist
if docker exec "$CONTAINER_NAME" test -d /var/log/supervisor; then
    test_result "Test 11: Log directory exists" "pass"
else
    test_result "Test 11: Log directory exists" "fail"
fi

echo -e "\n${BLUE}=== Python Environment Tests ===${NC}\n"

# Test 12: Flask is installed
if docker exec "$CONTAINER_NAME" python3 -c "import flask" 2>/dev/null; then
    test_result "Test 12: Flask package is installed" "pass"
else
    test_result "Test 12: Flask package is installed" "fail"
fi

# Test 13: Home Assistant is installed
if docker exec "$CONTAINER_NAME" python3 -c "import homeassistant" 2>/dev/null; then
    test_result "Test 13: Home Assistant package is installed" "pass"
else
    test_result "Test 13: Home Assistant package is installed" "fail"
fi

# Test 14: Required packages installed
required_packages="requests psutil pulsectl"
all_installed=true
for pkg in $required_packages; do
    if ! docker exec "$CONTAINER_NAME" python3 -c "import $pkg" 2>/dev/null; then
        all_installed=false
        break
    fi
done

if [ "$all_installed" = true ]; then
    test_result "Test 14: All required Python packages installed" "pass"
else
    test_result "Test 14: All required Python packages installed" "fail"
fi

echo -e "\n${BLUE}=== Application Log Tests ===${NC}\n"

# Test 15: No Flask errors in logs
if docker exec "$CONTAINER_NAME" tail -50 /var/log/supervisor/flask-api.err.log 2>/dev/null | grep -qi "error"; then
    test_result "Test 15: No Flask errors in logs" "warn" "Some errors found (may be expected)"
else
    test_result "Test 15: No Flask errors in logs" "pass"
fi

# Test 16: Flask started successfully
if docker exec "$CONTAINER_NAME" tail -50 /var/log/supervisor/flask-api.log 2>/dev/null | grep -q "Starting MediaBox AI"; then
    test_result "Test 16: Flask startup message found in logs" "pass"
else
    test_result "Test 16: Flask startup message found in logs" "warn"
fi

echo -e "\n${BLUE}=== Process Tests ===${NC}\n"

# Test 17: Flask process is running
if docker exec "$CONTAINER_NAME" pgrep -f "dashboard-api.py" > /dev/null; then
    test_result "Test 17: Flask process is active" "pass"
else
    test_result "Test 17: Flask process is active" "fail"
fi

# Test 18: Home Assistant process is running
if docker exec "$CONTAINER_NAME" pgrep -f "hass" > /dev/null; then
    test_result "Test 18: Home Assistant process is active" "pass"
else
    test_result "Test 18: Home Assistant process is active" "warn" "May still be starting"
fi

echo -e "\n${BLUE}=== Resource Usage Tests ===${NC}\n"

# Test 19: Container CPU usage is reasonable
cpu_usage=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}" | sed 's/%//')
if (( $(echo "$cpu_usage < 80" | bc -l) )); then
    test_result "Test 19: CPU usage is acceptable" "pass" "CPU: ${cpu_usage}%"
else
    test_result "Test 19: CPU usage is acceptable" "warn" "CPU: ${cpu_usage}% (high)"
fi

# Test 20: Container memory usage is reasonable
mem_usage=$(docker stats "$CONTAINER_NAME" --no-stream --format "{{.MemPerc}}" | sed 's/%//')
if (( $(echo "$mem_usage < 80" | bc -l) )); then
    test_result "Test 20: Memory usage is acceptable" "pass" "Memory: ${mem_usage}%"
else
    test_result "Test 20: Memory usage is acceptable" "warn" "Memory: ${mem_usage}% (high)"
fi

# Print summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}TEST SUMMARY${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
total=$((passed + failed + warnings))
echo -e "\nTotal Tests: $total"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo -e "${YELLOW}Warnings: $warnings${NC}"

success_rate=$(awk "BEGIN {printf \"%.1f\", ($passed / $total) * 100}")
echo -e "\n${BLUE}Success Rate: ${success_rate}%${NC}"

if [ $failed -eq 0 ]; then
    echo -e "\n${GREEN}✓ All critical server-side tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed. Please review the results above.${NC}"
    exit 1
fi

