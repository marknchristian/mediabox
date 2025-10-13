#!/bin/bash
# MediaBox AI - Complete ISO Building Workflow

set -e

# Set UTF-8 locale to handle Unicode properly
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

clea
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  MediaBox AI - ISO Builder Workflow${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Configuration
MEDIABOX_SRC="/mnt/c/Users/chris/@TVBOX/mediabox-dev"
UBUNTU_ISO="/mnt/c/HyperV/ISOs/ubuntu-22.04.3-desktop-amd64.iso"
OUTPUT_ISO="/mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso"
WORKSPACE="$HOME/mediabox-iso-builds"

# Check X Serve
echo -e "${BLUE}[CHECK]${NC} Testing X Server connection..."
if xset q &>/dev/null; then
    echo -e "${GREEN}âœ… X Server is running${NC}"
else
    echo -e "${RED}âŒ X Server not responding!${NC}"
    echo -e "${YELLOW}Please start VcXsrv on Windows:${NC}"
    echo -e "  Double-click: Start-XServer.bat on Desktop"
    echo ""
    read -p "Press Enter after starting X Server..."
    
    if ! xset q &>/dev/null; then
        echo -e "${RED}Still can't connect to X Server. Exiting.${NC}"
        exit 1
    fi
fi

# Check Ubuntu ISO
echo -e "${BLUE}[CHECK]${NC} Checking for Ubuntu base ISO..."
if [ ! -f "$UBUNTU_ISO" ]; then
    echo -e "${YELLOW}âš ï¸  Ubuntu ISO not found!${NC}"
    echo -e "${CYAN}Expected location: $UBUNTU_ISO${NC}"
    echo ""
    echo -e "${YELLOW}Download Ubuntu 22.04 LTS Desktop ISO:${NC}"
    echo -e "${CYAN}  https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso${NC}"
    echo ""
    echo -e "${YELLOW}Save to:${NC} C:\\HyperV\\ISOs\\"
    echo ""
    read -p "Press Enter when ISO is downloaded..."
    
    if [ ! -f "$UBUNTU_ISO" ]; then
        echo -e "${RED}ISO still not found. Exiting.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}âœ… Ubuntu ISO found${NC}"

# Check MediaBox source
echo -e "${BLUE}[CHECK]${NC} Checking MediaBox source files..."
if [ ! -d "$MEDIABOX_SRC" ]; then
    echo -e "${RED}âŒ MediaBox source not found: $MEDIABOX_SRC${NC}"
    exit 1
fi
echo -e "${GREEN}âœ… MediaBox source found${NC}"

# Create workspace
echo -e "${BLUE}[SETUP]${NC} Preparing workspace..."
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo ""
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  Ready to Build ISO!${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Source:    ${CYAN}$MEDIABOX_SRC${NC}"
echo -e "  Base ISO:  ${CYAN}$UBUNTU_ISO${NC}"
echo -e "  Output:    ${CYAN}$OUTPUT_ISO${NC}"
echo -e "  Workspace: ${CYAN}$WORKSPACE${NC}"
echo ""
echo -e "${YELLOW}What would you like to do?${NC}"
echo ""
echo -e "${GREEN}1)${NC} Launch Cubic GUI (interactive)"
echo -e "${GREEN}2)${NC} View Cubic quick guide"
echo -e "${GREEN}3)${NC} Test X Server"
echo -e "${GREEN}4)${NC} Exit"
echo ""
read -p "Select option [1-4]: " choice

case $choice in
    1)
        echo ""
        echo -e "${CYAN}Launching Cubic...${NC}"
        echo ""
        echo -e "${YELLOW}ðŸ“‹ Cubic Workflow Reminder:${NC}"
        echo -e "${BLUE}1.${NC} Project Directory: ${CYAN}$WORKSPACE${NC}"
        echo -e "${BLUE}2.${NC} Original ISO: ${CYAN}$UBUNTU_ISO${NC}"
        echo -e "${BLUE}3.${NC} In chroot terminal, run customization script"
        echo -e "${BLUE}4.${NC} Generate ISO and save to: ${CYAN}$OUTPUT_ISO${NC}"
        echo ""
        sleep 3
        cubic &
        ;;
    2)
        cat << 'GUIDE'

=========================================
  CUBIC QUICK GUIDE
=========================================

STEP 1: PROJECT SETUP
  - Click "Next"
  - Project directory: ~/mediabox-iso-builds
  - Click "Next"

STEP 2: SELECT BASE ISO
  - Original ISO: /mnt/c/HyperV/ISOs/ubuntu-22.04.3-desktop-amd64.iso
  - Custom ISO filename: mediabox-ai-v1.0
  - Click "Next" (wait for extraction)

STEP 3: CUSTOMIZE (Terminal opens)
  Copy and paste this into Cubic's terminal:

---BEGIN SCRIPT---
#!/bin/bash
set -e

# Update packages
apt update

# Install minimal X/window manage
apt install -y xorg openbox lightdm unclutte

# Install audio
apt install -y pulseaudio alsa-utils pavucontrol

# Install browsers/media
apt install -y chromium-browser vlc flatpak

# Install Python
apt install -y python3 python3-pip python3-venv

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Plex via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.plexamp.Plexamp

# Copy MediaBox files
mkdir -p /opt/mediabox
# (You'll manually copy files in next step)

# Clean up
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*

echo "Packages installed successfully!"
---END SCRIPT---

STEP 4: COPY MEDIABOX FILES
  In Cubic, click "Options" â†’ "Open Terminal"
  Run: cp -r /mnt/c/Users/chris/@TVBOX/mediabox-dev /opt/mediabox/

STEP 5: GENERATE ISO
  - Click "Next" through boot options
  - Generate ISO
  - Save to: /mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso

DONE! Test in Hyper-V VM

=========================================
GUIDE
        ;;
    3)
        ~/test-x-server.sh
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

