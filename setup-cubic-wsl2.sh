#!/bin/bash
# MediaBox AI - WSL2 Cubic Setup Script

set -e

# Set UTF-8 locale to handle Unicode properly
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  MediaBox AI - WSL2 Cubic Setup${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Check if running in WSL2
if ! grep -qi microsoft /proc/version; then
    echo -e "${RED}âŒ This script must run in WSL2!${NC}"
    exit 1
fi

echo -e "${GREEN}âœ… Running in WSL2${NC}"
echo ""

# Update system
echo -e "${GREEN}[1/8] Updating system packages...${NC}"
sudo apt update
sudo apt upgrade -y

# Install X11 dependencies
echo -e "${GREEN}[2/8] Installing X11 dependencies...${NC}"
sudo apt install -y \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    dbus-x11 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1

# Configure DISPLAY variable
echo -e "${GREEN}[3/8] Configuring DISPLAY variable...${NC}"

# Remove old DISPLAY configs if they exist
sed -i '/# X Server for GUI apps/d' ~/.bashrc
sed -i '/export DISPLAY=/d' ~/.bashrc
sed -i '/export LIBGL_ALWAYS_INDIRECT=/d' ~/.bashrc

# Add new configuration
cat >> ~/.bashrc << 'EOF'

# X Server for GUI apps (MediaBox AI)
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1
EOF

# Apply to current session
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1

echo -e "${GREEN}âœ… DISPLAY configured: $DISPLAY${NC}"

# Add Cubic PPA
echo -e "${GREEN}[4/8] Adding Cubic repository...${NC}"
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update

# Install Cubic
echo -e "${GREEN}[5/8] Installing Cubic...${NC}"
sudo apt install -y cubic

# Install additional ISO building tools
echo -e "${GREEN}[6/8] Installing ISO building tools...${NC}"
sudo apt install -y \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-utils \
    genisoimage \
    debootstrap

# Create workspace directories
echo -e "${GREEN}[7/8] Creating workspace directories...${NC}"
mkdir -p ~/mediabox-iso-builds
mkdir -p ~/mediabox-iso-builds/output

# Create ISO mount point in Windows-accessible location
mkdir -p /mnt/c/HyperV/ISOs 2>/dev/null || true

# Create helper scripts
echo -e "${GREEN}[8/8] Creating helper scripts...${NC}"

# Create test-x-server.sh
cat > ~/test-x-server.sh << 'TESTSCRIPT'
#!/bin/bash
# Test if X Server is running

echo "Testing X Server connection..."
echo "DISPLAY is set to: $DISPLAY"
echo ""

if command -v xclock &> /dev/null; then
    echo "Launching xclock (should appear on Windows desktop)..."
    xclock &
    CLOCK_PID=$!
    
    sleep 3
    
    if ps -p $CLOCK_PID > /dev/null; then
        echo "âœ… SUCCESS! X Server is working!"
        echo "You should see a clock on your Windows desktop"
        echo ""
        echo "Closing test window..."
        kill $CLOCK_PID 2>/dev/null
    else
        echo "âŒ FAILED! X Server not responding"
        echo ""
        echo "Troubleshooting:"
        echo "1. Make sure VcXsrv is running on Windows"
        echo "2. Check Windows Firewall settings"
        echo "3. Try: export DISPLAY=<windows-ip>:0"
    fi
else
    echo "âŒ xclock not installed"
fi
TESTSCRIPT

chmod +x ~/test-x-server.sh

# Create launch-cubic.sh
cat > ~/launch-cubic.sh << 'CUBICSCRIPT'
#!/bin/bash
# Launch Cubic with proper environment

# Set DISPLAY
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1

echo "========================================="
echo "  Launching Cubic"
echo "========================================="
echo "DISPLAY: $DISPLAY"
echo ""
echo "Make sure VcXsrv is running on Windows!"
echo "GUI should appear in ~5 seconds..."
echo ""

cd ~/mediabox-iso-builds
cubic &

echo ""
echo "Cubic launched in background (PID: $!)"
echo "If GUI doesn't appear, run: ~/test-x-server.sh"
CUBICSCRIPT

chmod +x ~/launch-cubic.sh

# Create quick-build-iso.sh
cat > ~/quick-build-iso.sh << 'QUICKSCRIPT'
#!/bin/bash
# Quick MediaBox ISO build script

set -e

MEDIABOX_SRC="/mnt/c/Users/chris/@TVBOX/mediabox-dev"
OUTPUT_ISO="/mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso"
WORKSPACE="$HOME/mediabox-iso-builds"

echo "========================================="
echo "  MediaBox AI - Quick ISO Builder"
echo "========================================="
echo ""
echo "Source: $MEDIABOX_SRC"
echo "Output: $OUTPUT_ISO"
echo "Workspace: $WORKSPACE"
echo ""

if [ ! -d "$MEDIABOX_SRC" ]; then
    echo "âŒ MediaBox source not found: $MEDIABOX_SRC"
    exit 1
fi

echo "Launching Cubic..."
echo "In Cubic:"
echo "1. Set project directory to: $WORKSPACE"
echo "2. Copy MediaBox files from: $MEDIABOX_SRC"
echo "3. Save ISO to: $OUTPUT_ISO"
echo ""

cd "$WORKSPACE"
~/launch-cubic.sh
QUICKSCRIPT

chmod +x ~/quick-build-iso.sh

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Setup Complete!${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${YELLOW}Important: Reload your shell or run:${NC}"
echo -e "${CYAN}  source ~/.bashrc${NC}"
echo ""
echo -e "${YELLOW}Quick Start Commands:${NC}"
echo -e "${GREEN}  ~/test-x-server.sh${NC}      - Test X Server connection"
echo -e "${GREEN}  ~/launch-cubic.sh${NC}       - Launch Cubic GUI"
echo -e "${GREEN}  ~/quick-build-iso.sh${NC}    - Quick build workflow"
echo ""
echo -e "${YELLOW}Workspace created at:${NC}"
echo -e "${CYAN}  ~/mediabox-iso-builds/${NC}"
echo ""
echo -e "${YELLOW}ISO output location:${NC}"
echo -e "${CYAN}  /mnt/c/HyperV/ISOs/${NC} (accessible from Windows)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Make sure VcXsrv is running on Windows"
echo -e "2. Run: ${GREEN}~/test-x-server.sh${NC}"
echo -e "3. If test passes, run: ${GREEN}~/launch-cubic.sh${NC}"
echo ""
