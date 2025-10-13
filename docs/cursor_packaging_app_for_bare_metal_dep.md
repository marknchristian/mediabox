# Packaging app for bare metal deployment
_Exported on 10/12/2025 at 13:31:42 GMT+2 from Cursor (1.7.36)_

---

**User**

provide the instructions on how to now backage this app to run baremetal on a pc connected to a projector including using GIT to maintain code updates.

---

**Cursor**

I'll help you create instructions for packaging and deploying this mediabox app as a baremetal installation on a PC. Let me first review the project structure and existing documentation.

Based on my review of your MediaBox AI project, I'll provide comprehensive instructions for packaging and deploying this app as a baremetal installation on a PC connected to a projector, with Git-based version control for updates.

## **MEDIABOX AI - BAREMETAL INSTALLATION GUIDE**

Here's a complete deployment guide for running MediaBox directly on hardware:

---

### **📋 PREREQUISITES**

**Hardware:**
- PC with Ubuntu 22.04 LTS or Ubuntu 24.04 LTS (recommended for stability)
- Projector connected via HDMI
- Minimum 4GB RAM, 8GB+ recommended
- Audio output (HDMI, SPDIF, or analog)

**Software to Install:**
```bash
sudo apt update
sudo apt upgrade -y

# Core system packages
sudo apt install -y \
  git \
  python3 \
  python3-pip \
  python3-venv \
  pulseaudio \
  pavucontrol \
  chromium-browser \
  vlc \
  flatpak \
  xorg \
  openbox \
  lightdm \
  unclutter \
  curl \
  wget

# Enable Flatpak and add Flathub repo (for Plex HTPC)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

---

### **🚀 INSTALLATION STEPS**

#### **1. Create MediaBox User (Optional but Recommended)**
```bash
# Create dedicated user for the media center
sudo adduser mediabox
sudo usermod -aG audio,video,sudo mediabox

# Switch to mediabox user
su - mediabox
```

#### **2. Clone Repository**
```bash
# Clone your MediaBox repository
cd ~
git clone <YOUR_GIT_REPO_URL> mediabox-app
cd mediabox-app/mediabox-dev

# Or if you don't have a remote repo yet, initialize one
cd ~/mediabox-app
git init
git add .
git commit -m "Initial MediaBox AI commit"
```

#### **3. Set Up Python Virtual Environment**
```bash
cd ~/mediabox-app/mediabox-dev

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

#### **4. Install Home Assistant (Optional)**
```bash
# Install Home Assistant in a virtual environment
sudo mkdir -p /opt/homeassistant
sudo chown mediabox:mediabox /opt/homeassistant
cd /opt/homeassistant
python3 -m venv ha_venv
source ha_venv/bin/activate
pip install homeassistant
deactivate
```

#### **5. Create System Service Files**

**Create `/etc/systemd/system/mediabox-api.service`:**
```ini
[Unit]
Description=MediaBox AI Dashboard API
After=network.target sound.target pulseaudio.service

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app/mediabox-dev
Environment="PATH=/home/mediabox/mediabox-app/mediabox-dev/venv/bin"
Environment="DISPLAY=:0"
Environment="PORT=8080"
ExecStart=/home/mediabox/mediabox-app/mediabox-dev/venv/bin/python3 /home/mediabox/mediabox-app/mediabox-dev/scripts/dashboard-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Create `/etc/systemd/system/homeassistant.service` (if using Home Assistant):**
```ini
[Unit]
Description=Home Assistant
After=network.target

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app/mediabox-dev/ha_config
Environment="PATH=/opt/homeassistant/ha_venv/bin"
ExecStart=/opt/homeassistant/ha_venv/bin/hass -c /home/mediabox/mediabox-app/mediabox-dev/ha_config
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start services:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable mediabox-api.service
sudo systemctl start mediabox-api.service

# If using Home Assistant
sudo systemctl enable homeassistant.service
sudo systemctl start homeassistant.service

# Check status
sudo systemctl status mediabox-api.service
sudo systemctl status homeassistant.service
```

#### **6. Configure Kiosk Mode for Projector**

**Create `/home/mediabox/.config/openbox/autostart`:**
```bash
mkdir -p /home/mediabox/.config/openbox
cat > /home/mediabox/.config/openbox/autostart << 'EOF'
# Hide mouse cursor when idle
unclutter -idle 0.1 &

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Wait for API server to be ready
sleep 5

# Launch dashboard in kiosk mode
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  --no-first-run \
  --fast \
  --fast-start \
  --disable-dinosaur-easter-egg \
  http://localhost:8080 &
EOF

chmod +x /home/mediabox/.config/openbox/autostart
```

#### **7. Configure Auto-Login**

Edit `/etc/lightdm/lightdm.conf`:
```bash
sudo nano /etc/lightdm/lightdm.conf
```

Add/modify these lines under `[Seat:*]`:
```ini
[Seat:*]
autologin-user=mediabox
autologin-user-timeout=0
user-session=openbox
```

#### **8. Set Display Resolution for Projector**
```bash
# Find your display and preferred resolution
xrandr

# Create display config
cat > /home/mediabox/.xprofile << 'EOF'
#!/bin/bash
# Set projector resolution (adjust as needed)
xrandr --output HDMI-1 --mode 1920x1080 --rate 60
EOF

chmod +x /home/mediabox/.xprofile
```

---

### **🔄 GIT-BASED UPDATE SYSTEM**

#### **Option 1: Create Update Script**

**Create `/home/mediabox/mediabox-app/update-mediabox.sh`:**
```bash
#!/bin/bash
# MediaBox AI Update Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  MediaBox AI Update${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Navigate to app directory
cd /home/mediabox/mediabox-app/mediabox-dev

# Check for local changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Warning: Local changes detected${NC}"
    echo "Stashing local changes..."
    git stash
fi

# Fetch latest changes
echo -e "${GREEN}Fetching updates from Git...${NC}"
git fetch origin

# Show what will be updated
echo ""
echo "Changes to be applied:"
git log HEAD..origin/main --oneline

# Confirm update
read -p "Apply these updates? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled"
    exit 1
fi

# Pull latest changes
echo -e "${GREEN}Pulling latest changes...${NC}"
git pull origin main

# Update Python dependencies
echo -e "${GREEN}Updating Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade -r requirements.txt
deactivate

# Restart services
echo -e "${GREEN}Restarting MediaBox services...${NC}"
sudo systemctl restart mediabox-api.service

# Optional: Restart Home Assistant if installed
if systemctl is-active --quiet homeassistant.service; then
    sudo systemctl restart homeassistant.service
fi

echo ""
echo -e "${GREEN}✓ Update complete!${NC}"
echo ""
echo "Services status:"
sudo systemctl status mediabox-api.service --no-pager -l
```

Make it executable:
```bash
chmod +x /home/mediabox/mediabox-app/update-mediabox.sh
```

#### **Option 2: Set Up Remote Git Repository**

**Create a GitHub/GitLab repository:**
```bash
# Initialize Git (if not already done)
cd ~/mediabox-app
git init

# Add all files
git add .
git commit -m "Initial MediaBox AI deployment"

# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/mediabox-ai.git

# Push to remote
git push -u origin main
```

**For future updates on the baremetal PC:**
```bash
cd ~/mediabox-app/mediabox-dev
./update-mediabox.sh
```

#### **Option 3: Automatic Updates (Optional)**

Create a cron job for automatic updates:
```bash
crontab -e
```

Add this line to check for updates daily at 3 AM:
```cron
0 3 * * * /home/mediabox/mediabox-app/update-mediabox.sh >> /home/mediabox/mediabox-update.log 2>&1
```

---

### **📦 OPTIONAL: INSTALL PLEX HTPC**

```bash
# Install Plex HTPC via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop

# Grant Plex access to network
flatpak override tv.plex.PlexDesktop --filesystem=host
```

---

### **🛠️ MAINTENANCE COMMANDS**

**View logs:**
```bash
# API service logs
sudo journalctl -u mediabox-api.service -f

# Home Assistant logs
sudo journalctl -u homeassistant.service -f

# All logs together
sudo journalctl -f
```

**Restart services:**
```bash
sudo systemctl restart mediabox-api.service
sudo systemctl restart homeassistant.service
```

**Test API:**
```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/status
```

**Update Git repository:**
```bash
cd ~/mediabox-app/mediabox-dev
./update-mediabox.sh
```

---

### **🔐 BACKUP STRATEGY**

**Create `/home/mediabox/backup-mediabox.sh`:**
```bash
#!/bin/bash
# MediaBox Backup Script

BACKUP_DIR="/home/mediabox/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mediabox_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_FILE"

tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
  --exclude='venv' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  -C /home/mediabox mediabox-app/mediabox-dev

echo "Backup complete: ${BACKUP_DIR}/${BACKUP_FILE}"

# Keep only last 7 backups
ls -t ${BACKUP_DIR}/mediabox_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
```

Make executable:
```bash
chmod +x /home/mediabox/backup-mediabox.sh
```

---

### **🎯 POST-INSTALLATION CHECKLIST**

- [ ] System boots to kiosk mode automatically
- [ ] Dashboard loads at http://localhost:8080
- [ ] Audio switching works (test with different outputs)
- [ ] Service launchers work (Netflix, Plex, YouTube, etc.)
- [ ] Home Assistant accessible at http://localhost:8123
- [ ] Git repository set up for updates
- [ ] Update script tested
- [ ] Backup script configured
- [ ] Projector display resolution correct
- [ ] Audio routed to correct output

---

### **🐛 TROUBLESHOOTING**

**Dashboard won't load:**
```bash
sudo systemctl status mediabox-api.service
sudo journalctl -u mediabox-api.service -n 50
```

**Audio not working:**
```bash
pactl list sinks short
python3 ~/mediabox-app/mediabox-dev/scripts/audio-switcher.py list
```

**Git updates failing:**
```bash
cd ~/mediabox-app/mediabox-dev
git status
git stash  # Save local changes
git pull origin main
```

**Chromium crashes on boot:**
```bash
# Clear Chromium cache
rm -rf ~/.cache/chromium
rm -rf ~/.config/chromium
```

---

### **📚 QUICK REFERENCE**

| Task | Command |
|------|---------|
| Update from Git | `~/mediabox-app/update-mediabox.sh` |
| Restart API | `sudo systemctl restart mediabox-api.service` |
| View logs | `sudo journalctl -u mediabox-api.service -f` |
| Check API health | `curl http://localhost:8080/api/health` |
| Backup config | `~/backup-mediabox.sh` |
| Reboot system | `sudo reboot` |

---

This baremetal setup gives you:
- ✅ Direct hardware access (better audio/video performance)
- ✅ Auto-start on boot (kiosk mode)
- ✅ Git-based version control
- ✅ Easy updates via script
- ✅ Systemd service management
- ✅ Full projector integration
- ✅ Backup/restore capability

Would you like me to create any of these configuration files for you, or would you like more details on any specific part of the setup?

```shellscript
sudo apt update
sudo apt upgrade -y

# Core system packages
sudo apt install -y \
  git \
  python3 \
  python3-pip \
  python3-venv \
  pulseaudio \
  pavucontrol \
  chromium-browser \
  vlc \
  flatpak \
  xorg \
  openbox \
  lightdm \
  unclutter \
  curl \
  wget

# Enable Flatpak and add Flathub repo (for Plex HTPC)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

```shellscript
# Create dedicated user for the media center
sudo adduser mediabox
sudo usermod -aG audio,video,sudo mediabox

# Switch to mediabox user
su - mediabox
```

```shellscript
# Clone your MediaBox repository
cd ~
git clone <YOUR_GIT_REPO_URL> mediabox-app
cd mediabox-app/mediabox-dev

# Or if you don't have a remote repo yet, initialize one
cd ~/mediabox-app
git init
git add .
git commit -m "Initial MediaBox AI commit"
```

```shellscript
cd ~/mediabox-app/mediabox-dev

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

```shellscript
# Install Home Assistant in a virtual environment
sudo mkdir -p /opt/homeassistant
sudo chown mediabox:mediabox /opt/homeassistant
cd /opt/homeassistant
python3 -m venv ha_venv
source ha_venv/bin/activate
pip install homeassistant
deactivate
```

```ini
[Unit]
Description=MediaBox AI Dashboard API
After=network.target sound.target pulseaudio.service

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app/mediabox-dev
Environment="PATH=/home/mediabox/mediabox-app/mediabox-dev/venv/bin"
Environment="DISPLAY=:0"
Environment="PORT=8080"
ExecStart=/home/mediabox/mediabox-app/mediabox-dev/venv/bin/python3 /home/mediabox/mediabox-app/mediabox-dev/scripts/dashboard-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```ini
[Unit]
Description=Home Assistant
After=network.target

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app/mediabox-dev/ha_config
Environment="PATH=/opt/homeassistant/ha_venv/bin"
ExecStart=/opt/homeassistant/ha_venv/bin/hass -c /home/mediabox/mediabox-app/mediabox-dev/ha_config
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```shellscript
sudo systemctl daemon-reload
sudo systemctl enable mediabox-api.service
sudo systemctl start mediabox-api.service

# If using Home Assistant
sudo systemctl enable homeassistant.service
sudo systemctl start homeassistant.service

# Check status
sudo systemctl status mediabox-api.service
sudo systemctl status homeassistant.service
```

```shellscript
mkdir -p /home/mediabox/.config/openbox
cat > /home/mediabox/.config/openbox/autostart << 'EOF'
# Hide mouse cursor when idle
unclutter -idle 0.1 &

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Wait for API server to be ready
sleep 5

# Launch dashboard in kiosk mode
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  --no-first-run \
  --fast \
  --fast-start \
  --disable-dinosaur-easter-egg \
  http://localhost:8080 &
EOF

chmod +x /home/mediabox/.config/openbox/autostart
```

```shellscript
sudo nano /etc/lightdm/lightdm.conf
```

```ini
[Seat:*]
autologin-user=mediabox
autologin-user-timeout=0
user-session=openbox
```

```shellscript
# Find your display and preferred resolution
xrandr

# Create display config
cat > /home/mediabox/.xprofile << 'EOF'
#!/bin/bash
# Set projector resolution (adjust as needed)
xrandr --output HDMI-1 --mode 1920x1080 --rate 60
EOF

chmod +x /home/mediabox/.xprofile
```

```shellscript
#!/bin/bash
# MediaBox AI Update Script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  MediaBox AI Update${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Navigate to app directory
cd /home/mediabox/mediabox-app/mediabox-dev

# Check for local changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Warning: Local changes detected${NC}"
    echo "Stashing local changes..."
    git stash
fi

# Fetch latest changes
echo -e "${GREEN}Fetching updates from Git...${NC}"
git fetch origin

# Show what will be updated
echo ""
echo "Changes to be applied:"
git log HEAD..origin/main --oneline

# Confirm update
read -p "Apply these updates? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled"
    exit 1
fi

# Pull latest changes
echo -e "${GREEN}Pulling latest changes...${NC}"
git pull origin main

# Update Python dependencies
echo -e "${GREEN}Updating Python dependencies...${NC}"
source venv/bin/activate
pip install --upgrade -r requirements.txt
deactivate

# Restart services
echo -e "${GREEN}Restarting MediaBox services...${NC}"
sudo systemctl restart mediabox-api.service

# Optional: Restart Home Assistant if installed
if systemctl is-active --quiet homeassistant.service; then
    sudo systemctl restart homeassistant.service
fi

echo ""
echo -e "${GREEN}✓ Update complete!${NC}"
echo ""
echo "Services status:"
sudo systemctl status mediabox-api.service --no-pager -l
```

```shellscript
chmod +x /home/mediabox/mediabox-app/update-mediabox.sh
```

```shellscript
# Initialize Git (if not already done)
cd ~/mediabox-app
git init

# Add all files
git add .
git commit -m "Initial MediaBox AI deployment"

# Add remote repository
git remote add origin https://github.com/YOUR_USERNAME/mediabox-ai.git

# Push to remote
git push -u origin main
```

```shellscript
cd ~/mediabox-app/mediabox-dev
./update-mediabox.sh
```

```shellscript
crontab -e
```

```plaintext
0 3 * * * /home/mediabox/mediabox-app/update-mediabox.sh >> /home/mediabox/mediabox-update.log 2>&1
```

```shellscript
# Install Plex HTPC via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop

# Grant Plex access to network
flatpak override tv.plex.PlexDesktop --filesystem=host
```

```shellscript
# API service logs
sudo journalctl -u mediabox-api.service -f

# Home Assistant logs
sudo journalctl -u homeassistant.service -f

# All logs together
sudo journalctl -f
```

```shellscript
sudo systemctl restart mediabox-api.service
sudo systemctl restart homeassistant.service
```

```shellscript
curl http://localhost:8080/api/health
curl http://localhost:8080/api/status
```

```shellscript
cd ~/mediabox-app/mediabox-dev
./update-mediabox.sh
```

```shellscript
#!/bin/bash
# MediaBox Backup Script

BACKUP_DIR="/home/mediabox/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mediabox_backup_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Creating backup: $BACKUP_FILE"

tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" \
  --exclude='venv' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  -C /home/mediabox mediabox-app/mediabox-dev

echo "Backup complete: ${BACKUP_DIR}/${BACKUP_FILE}"

# Keep only last 7 backups
ls -t ${BACKUP_DIR}/mediabox_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo "Old backups cleaned up"
```

```shellscript
chmod +x /home/mediabox/backup-mediabox.sh
```

```shellscript
sudo systemctl status mediabox-api.service
sudo journalctl -u mediabox-api.service -n 50
```

```shellscript
pactl list sinks short
python3 ~/mediabox-app/mediabox-dev/scripts/audio-switcher.py list
```

```shellscript
cd ~/mediabox-app/mediabox-dev
git status
git stash  # Save local changes
git pull origin main
```

```shellscript
# Clear Chromium cache
rm -rf ~/.cache/chromium
rm -rf ~/.config/chromium
```

---

**User**

I wanted to create an ISO to load from a USB or similar to create an installer for the HTPC I'm going to use to test. The test HTPC will be bare metal and server as my Test Buiild. Tell me ho to replicate the App with all the linux module needed, but no other bloat unles it helps in future, tell me how you would do that

---

**Cursor**

I'll provide you with a comprehensive guide to create a custom MediaBox AI ISO installer. This is the professional approach for creating a dedicated HTPC appliance.

## **CREATING A CUSTOM MEDIABOX AI ISO INSTALLER**

Perfect! I'll show you how to create a minimal, bootable MediaBox AI ISO that includes only what's needed. Based on your Dockerfile, I can see exactly what packages are required. Here's the professional approach:

---

## **🎯 APPROACH: Custom Ubuntu ISO with Pre-configured MediaBox**

I recommend **two methods** - pick the one that fits your workflow:

### **METHOD 1: CUBIC (GUI-Based - Easiest)**
### **METHOD 2: Debootstrap + Chroot (Command-Line - Most Control)**

---

## **METHOD 1: CUBIC - CUSTOM UBUNTU ISO CREATOR** ⭐ Recommended

This is the most user-friendly approach and gives you full control.

### **Step 1: Prepare Build Environment (on any Ubuntu/Debian PC)**

```bash
# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create working directory
mkdir -p ~/mediabox-iso-build
cd ~/mediabox-iso-build
```

### **Step 2: Download Base Ubuntu ISO**

```bash
# Download Ubuntu 24.04 LTS Server (minimal, no GUI bloat)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Or Ubuntu 22.04 LTS for maximum stability
# wget https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
```

### **Step 3: Launch Cubic and Customize**

```bash
# Launch Cubic
cubic
```

**In Cubic GUI:**
1. **Project Directory**: Choose `~/mediabox-iso-build`
2. **Original ISO**: Select the Ubuntu ISO you downloaded
3. **Click "Next"** until you reach the terminal

### **Step 4: In Cubic's Chroot Terminal, Install MediaBox Packages**

Once you're in the Cubic chroot terminal, run this comprehensive installation script:

```bash
#!/bin/bash
# MediaBox AI ISO Customization Script
# Run this inside Cubic's chroot terminal

set -e

echo "=========================================="
echo "  MediaBox AI Custom ISO Builder"
echo "=========================================="

# Update package lists
apt update

# Install only essential system packages (NO desktop environment)
apt install -y \
    linux-generic \
    linux-headers-generic \
    linux-firmware \
    network-manager \
    openssh-server \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    wireless-tools

# Install X server and minimal window manager (NO full DE)
apt install -y \
    xorg \
    xserver-xorg-video-all \
    xinit \
    openbox \
    lightdm \
    unclutter \
    xdotool

# Install audio system
apt install -y \
    pulseaudio \
    pulseaudio-utils \
    alsa-base \
    alsa-utils \
    pavucontrol

# Install Python 3.11+ and build tools
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    pkg-config

# Install Chromium browser (for kiosk mode)
apt install -y \
    chromium-browser

# Install VLC for IPTV
apt install -y \
    vlc \
    vlc-plugin-base

# Install Flatpak for Plex apps
apt install -y \
    flatpak \
    gnome-software-plugin-flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Plex HTPC and Plexamp via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.plexamp.Plexamp

# Install Home Assistant dependencies
apt install -y \
    libjpeg-dev \
    zlib1g-dev \
    autoconf \
    libopenjp2-7 \
    libtiff6 \
    libturbojpeg0 \
    tzdata \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev

# Install systemd services management
apt install -y \
    systemd

# Clean up to reduce ISO size
apt autoremove -y
apt autoclean
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "=========================================="
echo "  Base packages installed!"
echo "=========================================="
```

### **Step 5: Embed MediaBox Application in ISO**

Still in Cubic's chroot terminal:

```bash
# Create MediaBox directory structure
mkdir -p /opt/mediabox
cd /opt/mediabox

# You'll need to copy your MediaBox files here
# In Cubic, you can access files from your host system
# Copy from the Cubic project directory where you placed them

# For now, create the structure
mkdir -p dashboard scripts ha_config

# Create a placeholder - you'll copy actual files later
echo "MediaBox AI Installation Directory" > /opt/mediabox/README.txt

# Set permissions
chmod -R 755 /opt/mediabox
```

### **Step 6: Create First-Boot Setup Script**

Create `/usr/local/bin/mediabox-setup.sh`:

```bash
cat > /usr/local/bin/mediabox-setup.sh << 'SETUPSCRIPT'
#!/bin/bash
# MediaBox AI First Boot Setup

set -e

SETUP_FLAG="/var/lib/mediabox-setup-complete"

# Check if already setup
if [ -f "$SETUP_FLAG" ]; then
    echo "MediaBox already configured"
    exit 0
fi

echo "=========================================="
echo "  MediaBox AI - First Boot Setup"
echo "=========================================="

# Create mediabox user
if ! id mediabox &>/dev/null; then
    useradd -m -G audio,video,sudo -s /bin/bash mediabox
    echo "mediabox:mediabox" | chpasswd
    echo "Created user: mediabox / password: mediabox"
    echo "⚠️  CHANGE THIS PASSWORD AFTER FIRST LOGIN!"
fi

# Set up MediaBox directory
cp -r /opt/mediabox /home/mediabox/mediabox-app
chown -R mediabox:mediabox /home/mediabox/mediabox-app

# Create Python virtual environment
cd /home/mediabox/mediabox-app
sudo -u mediabox python3 -m venv venv
sudo -u mediabox /home/mediabox/mediabox-app/venv/bin/pip install --upgrade pip

# Install Python requirements if requirements.txt exists
if [ -f "/home/mediabox/mediabox-app/requirements.txt" ]; then
    sudo -u mediabox /home/mediabox/mediabox-app/venv/bin/pip install -r /home/mediabox/mediabox-app/requirements.txt
fi

# Configure auto-login for mediabox user
cat > /etc/lightdm/lightdm.conf.d/50-mediabox.conf << 'EOF'
[Seat:*]
autologin-user=mediabox
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

# Create Openbox autostart for kiosk mode
mkdir -p /home/mediabox/.config/openbox
cat > /home/mediabox/.config/openbox/autostart << 'EOF'
# Disable screen blanking and power saving
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor when idle
unclutter -idle 0.1 &

# Wait for API to start
sleep 8

# Launch MediaBox dashboard in kiosk mode
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --no-first-run \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  http://localhost:8080 &
EOF

chown -R mediabox:mediabox /home/mediabox/.config

# Create systemd service for MediaBox API
cat > /etc/systemd/system/mediabox-api.service << 'EOF'
[Unit]
Description=MediaBox AI Dashboard API
After=network.target sound.target

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app
Environment="PATH=/home/mediabox/mediabox-app/venv/bin"
Environment="DISPLAY=:0"
Environment="PORT=8080"
ExecStart=/home/mediabox/mediabox-app/venv/bin/python3 /home/mediabox/mediabox-app/scripts/dashboard-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable mediabox-api.service
systemctl enable lightdm.service

# Mark setup as complete
touch "$SETUP_FLAG"

echo "=========================================="
echo "  MediaBox AI Setup Complete!"
echo "=========================================="
echo ""
echo "System will reboot in 10 seconds..."
echo "Default login: mediabox / mediabox"
echo "⚠️  CHANGE PASSWORD AFTER LOGIN!"
sleep 10
reboot
SETUPSCRIPT

chmod +x /usr/local/bin/mediabox-setup.sh
```

### **Step 7: Create Systemd Service for First Boot**

```bash
cat > /etc/systemd/system/mediabox-firstboot.service << 'EOF'
[Unit]
Description=MediaBox AI First Boot Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mediabox-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable mediabox-firstboot.service
```

### **Step 8: Customize Boot Options**

In Cubic, go to the "Boot" tab and set:
- **ISO Name**: `MediaBox-AI-v1.0`
- **ISO Filename**: `mediabox-ai-v1.0-amd64.iso`
- **Boot Menu Timeout**: 5 seconds
- **Default Option**: Install MediaBox AI

### **Step 9: Generate ISO**

Click "Generate" in Cubic. Your custom ISO will be created in `~/mediabox-iso-build/`.

---

## **METHOD 2: MANUAL APPROACH (Advanced Control)**

If you want complete command-line control:

### **Create Complete ISO Build Script**

Create `build-mediabox-iso.sh`:

```bash
#!/bin/bash
# MediaBox AI ISO Builder
# Complete automated ISO creation

set -e

ISO_NAME="mediabox-ai"
ISO_VERSION="1.0"
ISO_LABEL="MediaBox AI"
WORK_DIR="$HOME/mediabox-iso-work"
ISO_DIR="$WORK_DIR/iso"
CHROOT_DIR="$WORK_DIR/chroot"
OUTPUT_ISO="$HOME/${ISO_NAME}-v${ISO_VERSION}-amd64.iso"

echo "=========================================="
echo "  MediaBox AI ISO Builder"
echo "=========================================="

# Install required tools
sudo apt install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

# Create working directories
mkdir -p "$ISO_DIR"/{casper,isolinux,install}
mkdir -p "$CHROOT_DIR"

echo "[1/8] Bootstrapping Ubuntu base system..."
sudo debootstrap \
    --arch=amd64 \
    --variant=minbase \
    jammy \
    "$CHROOT_DIR" \
    http://archive.ubuntu.com/ubuntu/

echo "[2/8] Configuring chroot environment..."

# Mount necessary filesystems
sudo mount --bind /dev "$CHROOT_DIR/dev"
sudo mount --bind /run "$CHROOT_DIR/run"
sudo mount -t proc none "$CHROOT_DIR/proc"
sudo mount -t sysfs none "$CHROOT_DIR/sys"
sudo mount -t devpts none "$CHROOT_DIR/dev/pts"

# Copy MediaBox files into chroot
echo "[3/8] Copying MediaBox application..."
sudo mkdir -p "$CHROOT_DIR/opt/mediabox"
sudo cp -r ./mediabox-dev/* "$CHROOT_DIR/opt/mediabox/"

# Create installation script
cat << 'CHROOT_SCRIPT' | sudo tee "$CHROOT_DIR/tmp/install-mediabox.sh" > /dev/null
#!/bin/bash
set -e

# Configure system
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export LC_ALL=C

# Update sources.list
cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF

apt update

# Install kernel and bootloader
apt install -y \
    linux-generic \
    grub-pc \
    grub-efi-amd64

# Install MediaBox packages (from Dockerfile analysis)
apt install -y \
    xorg \
    openbox \
    lightdm \
    chromium-browser \
    pulseaudio \
    alsa-utils \
    vlc \
    flatpak \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    network-manager \
    openssh-server \
    unclutter

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Plex via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.plexamp.Plexamp

# Clean up
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*

echo "MediaBox packages installed successfully"
CHROOT_SCRIPT

sudo chmod +x "$CHROOT_DIR/tmp/install-mediabox.sh"

echo "[4/8] Installing packages in chroot..."
sudo chroot "$CHROOT_DIR" /tmp/install-mediabox.sh

echo "[5/8] Creating filesystem image..."
sudo mksquashfs \
    "$CHROOT_DIR" \
    "$ISO_DIR/casper/filesystem.squashfs" \
    -comp xz \
    -e boot

echo "[6/8] Creating boot configuration..."

# Copy kernel and initrd
sudo cp "$CHROOT_DIR/boot/vmlinuz-"* "$ISO_DIR/casper/vmlinuz"
sudo cp "$CHROOT_DIR/boot/initrd.img-"* "$ISO_DIR/casper/initrd"

# Create grub.cfg
cat << 'EOF' | sudo tee "$ISO_DIR/boot/grub/grub.cfg" > /dev/null
set default="0"
set timeout=5

menuentry "Install MediaBox AI" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Install MediaBox AI (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}
EOF

echo "[7/8] Creating ISO image..."
sudo grub-mkrescue \
    -o "$OUTPUT_ISO" \
    "$ISO_DIR" \
    -- \
    -volid "$ISO_LABEL" \
    -joliet on \
    -rational-rock on

echo "[8/8] Cleaning up..."
sudo umount "$CHROOT_DIR/dev/pts"
sudo umount "$CHROOT_DIR/dev"
sudo umount "$CHROOT_DIR/run"
sudo umount "$CHROOT_DIR/proc"
sudo umount "$CHROOT_DIR/sys"
sudo rm -rf "$WORK_DIR"

echo "=========================================="
echo "  ISO Created Successfully!"
echo "=========================================="
echo ""
echo "ISO Location: $OUTPUT_ISO"
echo "ISO Size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "To write to USB:"
echo "  sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
echo ""
```

---

## **📦 MINIMAL PACKAGE LIST** (No Bloat)

Based on your Dockerfile, here's the **absolute minimum** needed:

### **Essential Packages Only:**
```
# Kernel & Boot
linux-generic
grub-pc / grub-efi-amd64

# Network
network-manager
openssh-server

# Display (NO full desktop)
xorg
openbox (lightweight window manager)
lightdm (minimal display manager)
unclutter

# Audio
pulseaudio
alsa-utils

# MediaBox Core
chromium-browser
python3
python3-pip
python3-venv
vlc
flatpak

# System Utils
git
curl
wget
systemd

# Plex (via Flatpak - outside apt)
tv.plex.PlexDesktop
com.plexamp.Plexamp
```

**Total installed size: ~1.2GB** (vs 4GB+ for Ubuntu Desktop)

---

## **🔥 CREATING THE BOOTABLE USB**

Once you have your ISO:

```bash
# Find your USB drive
lsblk

# Write ISO to USB (replace sdX with your drive)
sudo dd if=mediabox-ai-v1.0-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Or use a tool like Etcher (GUI)
# Download from: https://www.balena.io/etcher/
```

---

## **🎯 WHAT HAPPENS ON FIRST BOOT**

1. **Boot from USB** → GRUB menu appears
2. **Select "Install MediaBox AI"**
3. **Auto-installer runs** (no questions asked)
4. **System reboots**
5. **First boot setup** runs automatically:
   - Creates `mediabox` user
   - Installs Python packages
   - Configures kiosk mode
   - Starts services
6. **System reboots again**
7. **Dashboard launches automatically** in fullscreen

Total install time: **5-8 minutes** (depending on hardware)

---

## **📊 ISO SIZE COMPARISON**

| Distribution | Size | Bloat Level |
|--------------|------|-------------|
| Ubuntu Desktop | 4.7 GB | 🔴 High |
| Ubuntu Server | 2.5 GB | 🟡 Medium |
| **MediaBox AI (Custom)** | **~1.2 GB** | 🟢 **Minimal** |

---

## **💡 MY RECOMMENDATION**

**Use METHOD 1 (CUBIC)** because:
- ✅ GUI-based, easier to visualize
- ✅ Can test in VM before burning USB
- ✅ Easy to add/remove packages
- ✅ Built-in ISO validation
- ✅ Can create multiple versions easily

**Use METHOD 2** if you want:
- ⚡ Fully automated builds
- 🔄 CI/CD integration
- 🎯 Maximum control over every detail

---

Would you like me to create the **complete Cubic customization script** with all your MediaBox files embedded, or would you prefer the **fully automated command-line builder**?

```shellscript
# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create working directory
mkdir -p ~/mediabox-iso-build
cd ~/mediabox-iso-build
```

```shellscript
# Download Ubuntu 24.04 LTS Server (minimal, no GUI bloat)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Or Ubuntu 22.04 LTS for maximum stability
# wget https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso
```

```shellscript
# Launch Cubic
cubic
```

```shellscript
#!/bin/bash
# MediaBox AI ISO Customization Script
# Run this inside Cubic's chroot terminal

set -e

echo "=========================================="
echo "  MediaBox AI Custom ISO Builder"
echo "=========================================="

# Update package lists
apt update

# Install only essential system packages (NO desktop environment)
apt install -y \
    linux-generic \
    linux-headers-generic \
    linux-firmware \
    network-manager \
    openssh-server \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    wireless-tools

# Install X server and minimal window manager (NO full DE)
apt install -y \
    xorg \
    xserver-xorg-video-all \
    xinit \
    openbox \
    lightdm \
    unclutter \
    xdotool

# Install audio system
apt install -y \
    pulseaudio \
    pulseaudio-utils \
    alsa-base \
    alsa-utils \
    pavucontrol

# Install Python 3.11+ and build tools
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    libffi-dev \
    libssl-dev \
    pkg-config

# Install Chromium browser (for kiosk mode)
apt install -y \
    chromium-browser

# Install VLC for IPTV
apt install -y \
    vlc \
    vlc-plugin-base

# Install Flatpak for Plex apps
apt install -y \
    flatpak \
    gnome-software-plugin-flatpak

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Plex HTPC and Plexamp via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.plexamp.Plexamp

# Install Home Assistant dependencies
apt install -y \
    libjpeg-dev \
    zlib1g-dev \
    autoconf \
    libopenjp2-7 \
    libtiff6 \
    libturbojpeg0 \
    tzdata \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev

# Install systemd services management
apt install -y \
    systemd

# Clean up to reduce ISO size
apt autoremove -y
apt autoclean
apt clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "=========================================="
echo "  Base packages installed!"
echo "=========================================="
```

```shellscript
# Create MediaBox directory structure
mkdir -p /opt/mediabox
cd /opt/mediabox

# You'll need to copy your MediaBox files here
# In Cubic, you can access files from your host system
# Copy from the Cubic project directory where you placed them

# For now, create the structure
mkdir -p dashboard scripts ha_config

# Create a placeholder - you'll copy actual files later
echo "MediaBox AI Installation Directory" > /opt/mediabox/README.txt

# Set permissions
chmod -R 755 /opt/mediabox
```

```shellscript
cat > /usr/local/bin/mediabox-setup.sh << 'SETUPSCRIPT'
#!/bin/bash
# MediaBox AI First Boot Setup

set -e

SETUP_FLAG="/var/lib/mediabox-setup-complete"

# Check if already setup
if [ -f "$SETUP_FLAG" ]; then
    echo "MediaBox already configured"
    exit 0
fi

echo "=========================================="
echo "  MediaBox AI - First Boot Setup"
echo "=========================================="

# Create mediabox user
if ! id mediabox &>/dev/null; then
    useradd -m -G audio,video,sudo -s /bin/bash mediabox
    echo "mediabox:mediabox" | chpasswd
    echo "Created user: mediabox / password: mediabox"
    echo "⚠️  CHANGE THIS PASSWORD AFTER FIRST LOGIN!"
fi

# Set up MediaBox directory
cp -r /opt/mediabox /home/mediabox/mediabox-app
chown -R mediabox:mediabox /home/mediabox/mediabox-app

# Create Python virtual environment
cd /home/mediabox/mediabox-app
sudo -u mediabox python3 -m venv venv
sudo -u mediabox /home/mediabox/mediabox-app/venv/bin/pip install --upgrade pip

# Install Python requirements if requirements.txt exists
if [ -f "/home/mediabox/mediabox-app/requirements.txt" ]; then
    sudo -u mediabox /home/mediabox/mediabox-app/venv/bin/pip install -r /home/mediabox/mediabox-app/requirements.txt
fi

# Configure auto-login for mediabox user
cat > /etc/lightdm/lightdm.conf.d/50-mediabox.conf << 'EOF'
[Seat:*]
autologin-user=mediabox
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
EOF

# Create Openbox autostart for kiosk mode
mkdir -p /home/mediabox/.config/openbox
cat > /home/mediabox/.config/openbox/autostart << 'EOF'
# Disable screen blanking and power saving
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor when idle
unclutter -idle 0.1 &

# Wait for API to start
sleep 8

# Launch MediaBox dashboard in kiosk mode
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-restore-session-state \
  --no-first-run \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  http://localhost:8080 &
EOF

chown -R mediabox:mediabox /home/mediabox/.config

# Create systemd service for MediaBox API
cat > /etc/systemd/system/mediabox-api.service << 'EOF'
[Unit]
Description=MediaBox AI Dashboard API
After=network.target sound.target

[Service]
Type=simple
User=mediabox
Group=mediabox
WorkingDirectory=/home/mediabox/mediabox-app
Environment="PATH=/home/mediabox/mediabox-app/venv/bin"
Environment="DISPLAY=:0"
Environment="PORT=8080"
ExecStart=/home/mediabox/mediabox-app/venv/bin/python3 /home/mediabox/mediabox-app/scripts/dashboard-api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable mediabox-api.service
systemctl enable lightdm.service

# Mark setup as complete
touch "$SETUP_FLAG"

echo "=========================================="
echo "  MediaBox AI Setup Complete!"
echo "=========================================="
echo ""
echo "System will reboot in 10 seconds..."
echo "Default login: mediabox / mediabox"
echo "⚠️  CHANGE PASSWORD AFTER LOGIN!"
sleep 10
reboot
SETUPSCRIPT

chmod +x /usr/local/bin/mediabox-setup.sh
```

```shellscript
cat > /etc/systemd/system/mediabox-firstboot.service << 'EOF'
[Unit]
Description=MediaBox AI First Boot Setup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mediabox-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable mediabox-firstboot.service
```

```shellscript
#!/bin/bash
# MediaBox AI ISO Builder
# Complete automated ISO creation

set -e

ISO_NAME="mediabox-ai"
ISO_VERSION="1.0"
ISO_LABEL="MediaBox AI"
WORK_DIR="$HOME/mediabox-iso-work"
ISO_DIR="$WORK_DIR/iso"
CHROOT_DIR="$WORK_DIR/chroot"
OUTPUT_ISO="$HOME/${ISO_NAME}-v${ISO_VERSION}-amd64.iso"

echo "=========================================="
echo "  MediaBox AI ISO Builder"
echo "=========================================="

# Install required tools
sudo apt install -y \
    debootstrap \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools

# Create working directories
mkdir -p "$ISO_DIR"/{casper,isolinux,install}
mkdir -p "$CHROOT_DIR"

echo "[1/8] Bootstrapping Ubuntu base system..."
sudo debootstrap \
    --arch=amd64 \
    --variant=minbase \
    jammy \
    "$CHROOT_DIR" \
    http://archive.ubuntu.com/ubuntu/

echo "[2/8] Configuring chroot environment..."

# Mount necessary filesystems
sudo mount --bind /dev "$CHROOT_DIR/dev"
sudo mount --bind /run "$CHROOT_DIR/run"
sudo mount -t proc none "$CHROOT_DIR/proc"
sudo mount -t sysfs none "$CHROOT_DIR/sys"
sudo mount -t devpts none "$CHROOT_DIR/dev/pts"

# Copy MediaBox files into chroot
echo "[3/8] Copying MediaBox application..."
sudo mkdir -p "$CHROOT_DIR/opt/mediabox"
sudo cp -r ./mediabox-dev/* "$CHROOT_DIR/opt/mediabox/"

# Create installation script
cat << 'CHROOT_SCRIPT' | sudo tee "$CHROOT_DIR/tmp/install-mediabox.sh" > /dev/null
#!/bin/bash
set -e

# Configure system
export DEBIAN_FRONTEND=noninteractive
export HOME=/root
export LC_ALL=C

# Update sources.list
cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
EOF

apt update

# Install kernel and bootloader
apt install -y \
    linux-generic \
    grub-pc \
    grub-efi-amd64

# Install MediaBox packages (from Dockerfile analysis)
apt install -y \
    xorg \
    openbox \
    lightdm \
    chromium-browser \
    pulseaudio \
    alsa-utils \
    vlc \
    flatpak \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    network-manager \
    openssh-server \
    unclutter

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Plex via Flatpak
flatpak install -y flathub tv.plex.PlexDesktop
flatpak install -y flathub com.plexamp.Plexamp

# Clean up
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*

echo "MediaBox packages installed successfully"
CHROOT_SCRIPT

sudo chmod +x "$CHROOT_DIR/tmp/install-mediabox.sh"

echo "[4/8] Installing packages in chroot..."
sudo chroot "$CHROOT_DIR" /tmp/install-mediabox.sh

echo "[5/8] Creating filesystem image..."
sudo mksquashfs \
    "$CHROOT_DIR" \
    "$ISO_DIR/casper/filesystem.squashfs" \
    -comp xz \
    -e boot

echo "[6/8] Creating boot configuration..."

# Copy kernel and initrd
sudo cp "$CHROOT_DIR/boot/vmlinuz-"* "$ISO_DIR/casper/vmlinuz"
sudo cp "$CHROOT_DIR/boot/initrd.img-"* "$ISO_DIR/casper/initrd"

# Create grub.cfg
cat << 'EOF' | sudo tee "$ISO_DIR/boot/grub/grub.cfg" > /dev/null
set default="0"
set timeout=5

menuentry "Install MediaBox AI" {
    linux /casper/vmlinuz boot=casper quiet splash ---
    initrd /casper/initrd
}

menuentry "Install MediaBox AI (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset quiet splash ---
    initrd /casper/initrd
}
EOF

echo "[7/8] Creating ISO image..."
sudo grub-mkrescue \
    -o "$OUTPUT_ISO" \
    "$ISO_DIR" \
    -- \
    -volid "$ISO_LABEL" \
    -joliet on \
    -rational-rock on

echo "[8/8] Cleaning up..."
sudo umount "$CHROOT_DIR/dev/pts"
sudo umount "$CHROOT_DIR/dev"
sudo umount "$CHROOT_DIR/run"
sudo umount "$CHROOT_DIR/proc"
sudo umount "$CHROOT_DIR/sys"
sudo rm -rf "$WORK_DIR"

echo "=========================================="
echo "  ISO Created Successfully!"
echo "=========================================="
echo ""
echo "ISO Location: $OUTPUT_ISO"
echo "ISO Size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "To write to USB:"
echo "  sudo dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
echo ""
```

```plaintext
# Kernel & Boot
linux-generic
grub-pc / grub-efi-amd64

# Network
network-manager
openssh-server

# Display (NO full desktop)
xorg
openbox (lightweight window manager)
lightdm (minimal display manager)
unclutter

# Audio
pulseaudio
alsa-utils

# MediaBox Core
chromium-browser
python3
python3-pip
python3-venv
vlc
flatpak

# System Utils
git
curl
wget
systemd

# Plex (via Flatpak - outside apt)
tv.plex.PlexDesktop
com.plexamp.Plexamp
```

```shellscript
# Find your USB drive
lsblk

# Write ISO to USB (replace sdX with your drive)
sudo dd if=mediabox-ai-v1.0-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Or use a tool like Etcher (GUI)
# Download from: https://www.balena.io/etcher/
```

---

**User**

I would like to start with Cubic, does it make sense to test in a docker or does it really need a VM installed to tet it properly, and which is the best lightweight vm to run on my windows 10 pc

---

**Cursor**

Great question! Let me clarify the workflow and give you the optimal setup for Windows 10.

## **🎯 Docker vs VM: The Reality**

**Docker CANNOT test bootable ISOs** because:
- ❌ No bootloader (GRUB/systemd)
- ❌ No real init system
- ❌ Uses host kernel (can't test boot process)
- ❌ Can't test LightDM/X11 auto-start
- ❌ Can't test first-boot installation scripts

**You MUST use a VM** to properly test:
- ✅ Boot sequence
- ✅ Display manager (LightDM)
- ✅ Kiosk mode auto-start
- ✅ Hardware initialization
- ✅ Complete user experience

---

## **🖥️ BEST WORKFLOW FOR WINDOWS 10**

You'll need **TWO environments**:

### **1. Linux Environment to BUILD the ISO (Cubic runs on Ubuntu)**
### **2. VM to TEST the ISO**

---

## **📦 OPTION 1: Best for Windows 10** ⭐ **RECOMMENDED**

### **Setup:**

**A) VirtualBox for BOTH building AND testing:**

```
Windows 10 PC
├── VirtualBox VM #1: Ubuntu 22.04 (for building ISO with Cubic)
│   └── Inside: Run Cubic, create MediaBox ISO
└── VirtualBox VM #2: Empty VM (for testing the ISO)
    └── Boot from MediaBox ISO, test installation
```

**Why VirtualBox?**
- ✅ Free and open source
- ✅ Works on Windows 10 Home & Pro
- ✅ Good performance for development
- ✅ Easy snapshot/restore
- ✅ Excellent USB passthrough
- ✅ Can export OVA files for sharing

---

## **📋 STEP-BY-STEP: Complete Setup on Windows 10**

### **Step 1: Install VirtualBox**

```powershell
# Download and install VirtualBox
# Go to: https://www.virtualbox.org/wiki/Downloads
# Download: "Windows hosts" installer

# Or use winget (if you have it)
winget install Oracle.VirtualBox

# Also install Extension Pack for USB 3.0 support
# https://www.virtualbox.org/wiki/Downloads
```

### **Step 2: Create "ISO Builder" VM**

**In VirtualBox:**

1. **Click "New"**
2. **Configuration:**
   - Name: `MediaBox-ISO-Builder`
   - Type: Linux
   - Version: Ubuntu (64-bit)
   - RAM: **4GB minimum** (8GB recommended)
   - Disk: **50GB dynamic** (Cubic needs space for ISO extraction)
   - CPU: **2-4 cores**

3. **Settings adjustments:**
   ```
   System → Processor → 2-4 CPUs
   Display → Video Memory → 128MB
   Display → Graphics Controller → VMSVGA
   Storage → Add Ubuntu 22.04 ISO
   Network → Adapter 1 → NAT (for internet)
   ```

4. **Install Ubuntu 22.04:**
   - Download: https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso
   - Boot VM → Install Ubuntu
   - Choose "Minimal Installation"
   - Install VirtualBox Guest Additions after first boot

### **Step 3: Install Cubic in Builder VM**

**Inside your Ubuntu VM:**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create workspace
mkdir -p ~/mediabox-iso-builds

# Copy your MediaBox files to this VM
# Use VirtualBox Shared Folders or git clone
```

**Set up Shared Folder (to access Windows files):**
```bash
# In VirtualBox: Settings → Shared Folders → Add
# Folder Path: C:\Users\chris\@TVBOX\mediabox-dev
# Folder Name: mediabox-dev
# Check: Auto-mount, Make Permanent

# Inside Ubuntu VM:
sudo usermod -aG vboxsf $(whoami)
# Logout and login again
# Access at: /media/sf_mediabox-dev/
```

### **Step 4: Create "ISO Tester" VM**

**In VirtualBox, create second VM:**

1. **Click "New"**
2. **Configuration:**
   - Name: `MediaBox-Test`
   - Type: Linux
   - Version: Ubuntu (64-bit)
   - RAM: **4GB** (match your target hardware)
   - Disk: **25GB** (for installation test)
   - CPU: **2 cores**

3. **Important Settings:**
   ```
   System → Motherboard → Enable EFI
   Display → Video Memory → 128MB
   Audio → Enable Audio → Host Audio Driver
   Network → Adapter 1 → NAT or Bridged
   ```

4. **DON'T start it yet** - you'll boot from your custom ISO

---

## **🎮 ALTERNATIVE OPTIONS**

### **OPTION 2: Hyper-V (If you have Windows 10 Pro/Enterprise)**

**Pros:**
- ⚡ Better performance (native Windows hypervisor)
- 🔄 Better integration with Windows
- 💾 Lower overhead

**Cons:**
- ❌ Only on Pro/Enterprise/Education
- ❌ Conflicts with VirtualBox (can't use both)

**Enable Hyper-V:**
```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Or via GUI:
# Control Panel → Programs → Turn Windows features on/off → Hyper-V
```

**Setup:**
- Same concept: One VM for building, one for testing
- Use "Quick Create" → Ubuntu
- Better performance than VirtualBox

### **OPTION 3: WSL2 + VirtualBox Hybrid** 

**For Building ISO:**
```powershell
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu-22.04

# Inside WSL2:
sudo apt update
sudo apt install cubic

# Run Cubic with X server (requires VcXsrv or X410)
```

**For Testing ISO:**
- Use VirtualBox (as above)

**Complexity:** Higher (need X server setup)

### **OPTION 4: VMware Workstation Player** (Free for personal use)

**Alternative to VirtualBox:**
- Download: https://www.vmware.com/products/workstation-player.html
- Similar to VirtualBox but often faster
- Better 3D graphics support
- Setup is identical to VirtualBox

---

## **💡 MY RECOMMENDATION FOR YOU**

Based on Windows 10 + your workflow:

### **Use VirtualBox** with this setup:

```
Your Windows 10 PC
│
├── VirtualBox VM: "MediaBox-Builder" (Ubuntu 22.04 Desktop)
│   ├── RAM: 6-8GB
│   ├── Disk: 50GB
│   ├── Shared Folder → Your Windows @TVBOX folder
│   └── Purpose: Run Cubic, build custom ISOs
│
└── VirtualBox VM: "MediaBox-Test" (Empty, for ISO testing)
    ├── RAM: 4GB (match your target HTPC)
    ├── Disk: 25GB
    ├── Purpose: Boot and test your MediaBox ISO
    └── Can create multiple snapshots for testing
```

### **Workflow:**

1. **In Windows:** Edit MediaBox files in VS Code/Cursor
2. **In Builder VM:** 
   - Access files via shared folder
   - Run Cubic
   - Build ISO
   - Save ISO to shared folder
3. **In Test VM:** 
   - Mount ISO
   - Boot and test
   - Take snapshots at different stages
   - Reset and retest as needed

---

## **⚙️ OPTIMAL VM SPECS FOR YOUR USE CASE**

### **ISO Builder VM:**
```yaml
OS: Ubuntu 22.04 Desktop
RAM: 6GB (Cubic is memory-intensive)
Disk: 50GB dynamic
CPUs: 2-4 cores
Video: 128MB
Network: NAT
Shared Folders: YES (to access Windows files)
```

### **ISO Test VM:**
```yaml
OS: Boot from custom ISO
RAM: 4GB (match target HTPC)
Disk: 25GB (for full installation test)
CPUs: 2 cores (match target HTPC)
Video: 128MB
Network: NAT or Bridged
Audio: Enabled (test PulseAudio)
EFI: Enabled (modern boot)
```

---

## **🚀 QUICK START COMMANDS**

**After installing VirtualBox:**

```powershell
# Create ISO Builder VM via CLI (alternative to GUI)
VBoxManage createvm --name "MediaBox-Builder" --ostype Ubuntu_64 --register
VBoxManage modifyvm "MediaBox-Builder" --memory 6144 --cpus 2 --vram 128
VBoxManage createhd --filename "MediaBox-Builder.vdi" --size 51200
VBoxManage storagectl "MediaBox-Builder" --name "SATA" --add sata --controller IntelAHCI
VBoxManage storageattach "MediaBox-Builder" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "MediaBox-Builder.vdi"

# Attach Ubuntu ISO
VBoxManage storageattach "MediaBox-Builder" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "C:\Path\To\ubuntu-22.04.3-desktop-amd64.iso"

# Start VM
VBoxManage startvm "MediaBox-Builder"
```

---

## **📊 COMPARISON TABLE**

| Solution | Performance | Ease of Use | Cost | Windows 10 Home | Recommended |
|----------|-------------|-------------|------|-----------------|-------------|
| **VirtualBox** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Free | ✅ Yes | ✅ **Best Choice** |
| **Hyper-V** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | ❌ Pro only | ⭐ If you have Pro |
| **VMware Player** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Free | ✅ Yes | Alternative |
| **WSL2 + X** | ⭐⭐ | ⭐⭐ | Free | ✅ Yes | Advanced users |

---

## **🎯 FINAL ANSWER**

**For your situation:**

1. ✅ **Install VirtualBox** (works on Windows 10 Home)
2. ✅ **Create Ubuntu 22.04 VM** (6GB RAM, 50GB disk) for building
3. ✅ **Install Cubic inside that VM**
4. ✅ **Create empty test VM** (4GB RAM) for testing ISOs
5. ✅ **Use Shared Folders** to access your Windows files

**Total time to set up:** ~45 minutes
**Disk space needed:** ~120GB (Ubuntu ISO + 2 VMs)

This gives you a professional ISO development workflow without needing to dual-boot or use a separate physical machine!

Want me to provide the **exact VirtualBox setup script** or **step-by-step screenshots guide**?

```plaintext
Windows 10 PC
├── VirtualBox VM #1: Ubuntu 22.04 (for building ISO with Cubic)
│   └── Inside: Run Cubic, create MediaBox ISO
└── VirtualBox VM #2: Empty VM (for testing the ISO)
    └── Boot from MediaBox ISO, test installation
```

```powershell
# Download and install VirtualBox
# Go to: https://www.virtualbox.org/wiki/Downloads
# Download: "Windows hosts" installer

# Or use winget (if you have it)
winget install Oracle.VirtualBox

# Also install Extension Pack for USB 3.0 support
# https://www.virtualbox.org/wiki/Downloads
```

```plaintext
   System → Processor → 2-4 CPUs
   Display → Video Memory → 128MB
   Display → Graphics Controller → VMSVGA
   Storage → Add Ubuntu 22.04 ISO
   Network → Adapter 1 → NAT (for internet)
```

```shellscript
# Update system
sudo apt update && sudo apt upgrade -y

# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create workspace
mkdir -p ~/mediabox-iso-builds

# Copy your MediaBox files to this VM
# Use VirtualBox Shared Folders or git clone
```

```shellscript
# In VirtualBox: Settings → Shared Folders → Add
# Folder Path: C:\Users\chris\@TVBOX\mediabox-dev
# Folder Name: mediabox-dev
# Check: Auto-mount, Make Permanent

# Inside Ubuntu VM:
sudo usermod -aG vboxsf $(whoami)
# Logout and login again
# Access at: /media/sf_mediabox-dev/
```

```plaintext
   System → Motherboard → Enable EFI
   Display → Video Memory → 128MB
   Audio → Enable Audio → Host Audio Driver
   Network → Adapter 1 → NAT or Bridged
```

```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Or via GUI:
# Control Panel → Programs → Turn Windows features on/off → Hyper-V
```

```powershell
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu-22.04

# Inside WSL2:
sudo apt update
sudo apt install cubic

# Run Cubic with X server (requires VcXsrv or X410)
```

```plaintext
Your Windows 10 PC
│
├── VirtualBox VM: "MediaBox-Builder" (Ubuntu 22.04 Desktop)
│   ├── RAM: 6-8GB
│   ├── Disk: 50GB
│   ├── Shared Folder → Your Windows @TVBOX folder
│   └── Purpose: Run Cubic, build custom ISOs
│
└── VirtualBox VM: "MediaBox-Test" (Empty, for ISO testing)
    ├── RAM: 4GB (match your target HTPC)
    ├── Disk: 25GB
    ├── Purpose: Boot and test your MediaBox ISO
    └── Can create multiple snapshots for testing
```

```yaml
OS: Ubuntu 22.04 Desktop
RAM: 6GB (Cubic is memory-intensive)
Disk: 50GB dynamic
CPUs: 2-4 cores
Video: 128MB
Network: NAT
Shared Folders: YES (to access Windows files)
```

```yaml
OS: Boot from custom ISO
RAM: 4GB (match target HTPC)
Disk: 25GB (for full installation test)
CPUs: 2 cores (match target HTPC)
Video: 128MB
Network: NAT or Bridged
Audio: Enabled (test PulseAudio)
EFI: Enabled (modern boot)
```

```powershell
# Create ISO Builder VM via CLI (alternative to GUI)
VBoxManage createvm --name "MediaBox-Builder" --ostype Ubuntu_64 --register
VBoxManage modifyvm "MediaBox-Builder" --memory 6144 --cpus 2 --vram 128
VBoxManage createhd --filename "MediaBox-Builder.vdi" --size 51200
VBoxManage storagectl "MediaBox-Builder" --name "SATA" --add sata --controller IntelAHCI
VBoxManage storageattach "MediaBox-Builder" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "MediaBox-Builder.vdi"

# Attach Ubuntu ISO
VBoxManage storageattach "MediaBox-Builder" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "C:\Path\To\ubuntu-22.04.3-desktop-amd64.iso"

# Start VM
VBoxManage startvm "MediaBox-Builder"
```

---

**User**

I have hyperv

---

**Cursor**

Perfect! **Hyper-V is actually BETTER** than VirtualBox for this. You'll get better performance since it's a Type 1 hypervisor. Here's your optimized setup:

---

## **🚀 MEDIABOX ISO BUILDER - HYPER-V SETUP**

### **✅ What You Already Have**
- Windows 10 Pro/Enterprise/Education
- Hyper-V available (likely already enabled)

---

## **Step 1: Verify/Enable Hyper-V**

**Check if enabled:**
```powershell
# Run PowerShell as Administrator
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
```

**If not enabled, enable it:**
```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Reboot when prompted
Restart-Computer
```

---

## **Step 2: Create Virtual Switch (Network)**

**Open PowerShell as Administrator:**

```powershell
# Create an External virtual switch (for internet access)
New-VMSwitch -Name "MediaBox-Network" -NetAdapterName (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name -AllowManagementOS $true

# Or create Internal switch if you prefer
# New-VMSwitch -Name "MediaBox-Internal" -SwitchType Internal
```

**Or via Hyper-V Manager GUI:**
1. Open Hyper-V Manager
2. Right-click your computer → Virtual Switch Manager
3. New virtual network switch → External
4. Name: `MediaBox-Network`
5. Connect to: Your physical network adapter
6. ✅ Allow management OS to share this network adapter

---

## **Step 3: Download Ubuntu 22.04 ISO**

```powershell
# Create ISO directory
New-Item -Path "C:\HyperV\ISOs" -ItemType Directory -Force

# Download Ubuntu 22.04 Desktop
$ubuntuUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
$isoPath = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"

# Download (or just download via browser and save to C:\HyperV\ISOs\)
Start-BitsTransfer -Source $ubuntuUrl -Destination $isoPath
```

---

## **Step 4: Create "MediaBox-Builder" VM**

**PowerShell method (fast):**

```powershell
# Create VM for ISO building
$vmName = "MediaBox-Builder"
$vmPath = "C:\HyperV\VMs"
$isoPath = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"

# Create directories
New-Item -Path $vmPath -ItemType Directory -Force

# Create VM with optimal settings
New-VM -Name $vmName `
    -MemoryStartupBytes 8GB `
    -Generation 2 `
    -NewVHDPath "$vmPath\$vmName.vhdx" `
    -NewVHDSizeBytes 60GB `
    -SwitchName "MediaBox-Network"

# Configure VM
Set-VM -Name $vmName `
    -ProcessorCount 4 `
    -DynamicMemory `
    -MemoryMinimumBytes 4GB `
    -MemoryMaximumBytes 8GB `
    -AutomaticCheckpointsEnabled $false

# Disable Secure Boot (required for Ubuntu)
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Add DVD drive with Ubuntu ISO
Add-VMDvdDrive -VMName $vmName -Path $isoPath

# Set DVD as first boot device
$dvd = Get-VMDvdDrive -VMName $vmName
Set-VMFirmware -VMName $vmName -FirstBootDevice $dvd

# Enable Enhanced Session (better clipboard/resolution)
Set-VM -VMName $vmName -EnhancedSessionTransportType HvSocket

Write-Host "✅ VM Created: $vmName" -ForegroundColor Green
Write-Host "📀 Boot from: $isoPath" -ForegroundColor Cyan
Write-Host "🚀 Start VM in Hyper-V Manager" -ForegroundColor Yellow
```

**Or via Hyper-V Manager GUI:**
1. Open **Hyper-V Manager**
2. Right-click your PC → **New → Virtual Machine**
3. **Specify Name and Location:**
   - Name: `MediaBox-Builder`
   - Store: `C:\HyperV\VMs\`
4. **Specify Generation:** Generation 2 (UEFI)
5. **Assign Memory:** 8192 MB, enable Dynamic Memory
6. **Configure Networking:** Select `MediaBox-Network`
7. **Create Virtual Hard Disk:** 60 GB
8. **Installation Options:** Install from ISO → Select Ubuntu ISO
9. **Finish**

**Important: Before starting:**
- Right-click VM → **Settings**
- Security → **Disable Secure Boot** (Ubuntu won't boot otherwise)
- Processor → **4 virtual processors**
- Checkpoints → **Disable automatic checkpoints**

---

## **Step 5: Install Ubuntu in Builder VM**

1. **Start VM** in Hyper-V Manager
2. **Connect** to VM console
3. **Install Ubuntu 22.04:**
   - Language: English
   - Installation type: **Minimal installation** ✅
   - Updates: Download updates while installing
   - Other software: ✅ Install third-party software
   - Disk: Erase disk and install Ubuntu (it's a VM, safe!)
   - Create user: `mediabox` / password: `mediabox`
4. **Restart** when prompted
5. **After first boot:**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Hyper-V guest tools (Enhanced Session support)
sudo apt install -y linux-tools-virtual linux-cloud-tools-virtual

# Enable Enhanced Session
sudo nano /etc/xrdp/xrdp.ini
# Change: port=3389 to port=vsock://-1:3389
# Save and exit

sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Reboot VM
sudo reboot
```

---

## **Step 6: Install Cubic in Builder VM**

**After reboot, inside Ubuntu VM:**

```bash
# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create workspace
mkdir -p ~/mediabox-iso-builds
cd ~/mediabox-iso-builds

# Copy your MediaBox files
# Option 1: Clone from Git
git clone <YOUR_GIT_REPO> mediabox-source

# Option 2: Copy from Windows using shared folder (see below)
```

---

## **Step 7: Access Windows Files from Ubuntu VM**

**Method 1: SMB Share (Easiest)**

**On Windows (PowerShell as Admin):**
```powershell
# Share your MediaBox folder
$sharePath = "C:\Users\chris\@TVBOX\mediabox-dev"
New-SmbShare -Name "mediabox" -Path $sharePath -FullAccess "Everyone"

# Note your Windows IP
ipconfig | findstr IPv4
```

**In Ubuntu VM:**
```bash
# Install CIFS utilities
sudo apt install -y cifs-utils

# Create mount point
sudo mkdir -p /mnt/windows-mediabox

# Mount Windows share (replace IP)
sudo mount -t cifs //YOUR_WINDOWS_IP/mediabox /mnt/windows-mediabox -o username=chris,vers=3.0

# Copy files
cp -r /mnt/windows-mediabox ~/mediabox-iso-builds/mediabox-source
```

**Method 2: Set up Shared Folder via Hyper-V** (More complex, less reliable)

**Method 3: Use Git** (Recommended for version control)

```bash
# In Ubuntu VM
cd ~/mediabox-iso-builds
git clone https://github.com/yourusername/mediabox-ai.git mediabox-source
```

---

## **Step 8: Create "MediaBox-Test" VM**

**PowerShell:**

```powershell
# Create test VM (no ISO attached yet)
$testVMName = "MediaBox-Test"
$vmPath = "C:\HyperV\VMs"

New-VM -Name $testVMName `
    -MemoryStartupBytes 4GB `
    -Generation 2 `
    -NewVHDPath "$vmPath\$testVMName.vhdx" `
    -NewVHDSizeBytes 30GB `
    -SwitchName "MediaBox-Network"

Set-VM -Name $testVMName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $true

# Disable Secure Boot
Set-VMFirmware -VMName $testVMName -EnableSecureBoot Off

# Add empty DVD drive (for your custom ISO later)
Add-VMDvdDrive -VMName $testVMName

Write-Host "✅ Test VM Created: $testVMName" -ForegroundColor Green
Write-Host "📀 Attach your MediaBox ISO when ready" -ForegroundColor Cyan
```

---

## **🎯 YOUR WORKFLOW**

### **Building Phase:**

```
Windows 10 (Hyper-V Host)
    ↓
MediaBox-Builder VM (Ubuntu 22.04)
    ↓
1. Access MediaBox files (via SMB or Git)
2. Launch Cubic
3. Build custom ISO
4. Save ISO to shared location
```

### **Testing Phase:**

```
Windows 10 (Hyper-V Host)
    ↓
MediaBox-Test VM (empty)
    ↓
1. Attach MediaBox ISO to DVD drive
2. Boot VM
3. Test installation
4. Test auto-start, kiosk mode
5. Create checkpoint if successful
6. Reset and test again
```

---

## **🔥 HYPER-V SPECIFIC TIPS**

### **Enhanced Session Mode** (Better than VirtualBox!)

After enabling xrdp in Ubuntu:
- Full clipboard integration
- Dynamic resolution (resize window = resize desktop)
- Better mouse integration
- Audio redirection

### **Checkpoints (Snapshots)**

```powershell
# Create checkpoint before testing
Checkpoint-VM -Name "MediaBox-Test" -SnapshotName "Before-ISO-Test"

# Restore checkpoint
Restore-VMCheckpoint -Name "Before-ISO-Test" -VMName "MediaBox-Test" -Confirm:$false

# Delete checkpoint
Remove-VMCheckpoint -VMName "MediaBox-Test" -Name "Before-ISO-Test"
```

### **Mount ISO to Test VM**

```powershell
# After building ISO in Builder VM, copy to Windows
# Then attach to Test VM
$isoPath = "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"
Set-VMDvdDrive -VMName "MediaBox-Test" -Path $isoPath

# Set boot order to DVD first
$dvd = Get-VMDvdDrive -VMName "MediaBox-Test"
Set-VMFirmware -VMName "MediaBox-Test" -FirstBootDevice $dvd
```

### **Quick Commands**

```powershell
# Start VMs
Start-VM -Name "MediaBox-Builder"
Start-VM -Name "MediaBox-Test"

# Stop VMs
Stop-VM -Name "MediaBox-Builder"
Stop-VM -Name "MediaBox-Test" -Force

# Connect to VM
vmconnect.exe localhost "MediaBox-Builder"

# Get VM status
Get-VM | Format-Table Name, State, CPUUsage, MemoryAssigned
```

---

## **📦 COMPLETE HYPER-V SETUP SCRIPT**

Save this as `Setup-MediaBoxHyperV.ps1`:

```powershell
#Requires -RunAsAdministrator
# MediaBox AI - Hyper-V Setup Script

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI - Hyper-V Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$vmPath = "C:\HyperV\VMs"
$isoPath = "C:\HyperV\ISOs"
$ubuntuISO = "$isoPath\ubuntu-22.04.3-desktop-amd64.iso"
$switchName = "MediaBox-Network"

# Create directories
Write-Host "[1/5] Creating directories..." -ForegroundColor Green
New-Item -Path $vmPath -ItemType Directory -Force | Out-Null
New-Item -Path $isoPath -ItemType Directory -Force | Out-Null

# Create virtual switch if it doesn't exist
Write-Host "[2/5] Creating virtual switch..." -ForegroundColor Green
if (!(Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue)) {
    $netAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    New-VMSwitch -Name $switchName -NetAdapterName $netAdapter.Name -AllowManagementOS $true
    Write-Host "✅ Virtual switch created: $switchName" -ForegroundColor Green
} else {
    Write-Host "✅ Virtual switch already exists: $switchName" -ForegroundColor Yellow
}

# Check for Ubuntu ISO
Write-Host "[3/5] Checking Ubuntu ISO..." -ForegroundColor Green
if (!(Test-Path $ubuntuISO)) {
    Write-Host "⚠️  Ubuntu ISO not found!" -ForegroundColor Red
    Write-Host "Please download Ubuntu 22.04 Desktop ISO and save to:" -ForegroundColor Yellow
    Write-Host "  $ubuntuISO" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Download from: https://releases.ubuntu.com/22.04/" -ForegroundColor Cyan
    exit
}

# Create Builder VM
Write-Host "[4/5] Creating MediaBox-Builder VM..." -ForegroundColor Green
$builderName = "MediaBox-Builder"
if (Get-VM -Name $builderName -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  VM already exists: $builderName" -ForegroundColor Yellow
} else {
    New-VM -Name $builderName `
        -MemoryStartupBytes 8GB `
        -Generation 2 `
        -NewVHDPath "$vmPath\$builderName.vhdx" `
        -NewVHDSizeBytes 60GB `
        -SwitchName $switchName
    
    Set-VM -Name $builderName `
        -ProcessorCount 4 `
        -DynamicMemory `
        -MemoryMinimumBytes 4GB `
        -MemoryMaximumBytes 8GB `
        -AutomaticCheckpointsEnabled $false
    
    Set-VMFirmware -VMName $builderName -EnableSecureBoot Off
    Add-VMDvdDrive -VMName $builderName -Path $ubuntuISO
    
    $dvd = Get-VMDvdDrive -VMName $builderName
    Set-VMFirmware -VMName $builderName -FirstBootDevice $dvd
    
    Write-Host "✅ Created: $builderName" -ForegroundColor Green
}

# Create Test VM
Write-Host "[5/5] Creating MediaBox-Test VM..." -ForegroundColor Green
$testName = "MediaBox-Test"
if (Get-VM -Name $testName -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  VM already exists: $testName" -ForegroundColor Yellow
} else {
    New-VM -Name $testName `
        -MemoryStartupBytes 4GB `
        -Generation 2 `
        -NewVHDPath "$vmPath\$testName.vhdx" `
        -NewVHDSizeBytes 30GB `
        -SwitchName $switchName
    
    Set-VM -Name $testName `
        -ProcessorCount 2 `
        -DynamicMemory `
        -MemoryMinimumBytes 2GB `
        -MemoryMaximumBytes 4GB `
        -AutomaticCheckpointsEnabled $true
    
    Set-VMFirmware -VMName $testName -EnableSecureBoot Off
    Add-VMDvdDrive -VMName $testName
    
    Write-Host "✅ Created: $testName" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start MediaBox-Builder VM" -ForegroundColor White
Write-Host "   Start-VM -Name 'MediaBox-Builder'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Install Ubuntu 22.04 in Builder VM" -ForegroundColor White
Write-Host "   - Choose 'Minimal Installation'" -ForegroundColor Gray
Write-Host "   - Install Cubic after first boot" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Build your MediaBox ISO in Cubic" -ForegroundColor White
Write-Host ""
Write-Host "4. Test ISO in MediaBox-Test VM" -ForegroundColor White
Write-Host "   Set-VMDvdDrive -VMName 'MediaBox-Test' -Path 'path\to\your.iso'" -ForegroundColor Gray
Write-Host ""
```

**Run it:**
```powershell
# Save the script, then:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Setup-MediaBoxHyperV.ps1
```

---

## **✅ ADVANTAGES OF HYPER-V FOR YOUR USE CASE**

- ⚡ **Better Performance** - Type 1 hypervisor
- 🔄 **Checkpoints** - Built-in snapshot system
- 🖥️ **Enhanced Session** - Better than VirtualBox RDP
- 💾 **Dynamic Memory** - More efficient RAM usage
- 🔌 **Native Windows Integration** - PowerShell automation
- 🆓 **Free** - Already included in Windows 10 Pro

---

**You're all set!** Use the PowerShell script above to create both VMs, then proceed with the Cubic ISO building workflow. Let me know if you need help with any step!

```powershell
# Run PowerShell as Administrator
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
```

```powershell
# Run as Administrator
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Reboot when prompted
Restart-Computer
```

```powershell
# Create an External virtual switch (for internet access)
New-VMSwitch -Name "MediaBox-Network" -NetAdapterName (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name -AllowManagementOS $true

# Or create Internal switch if you prefer
# New-VMSwitch -Name "MediaBox-Internal" -SwitchType Internal
```

```powershell
# Create ISO directory
New-Item -Path "C:\HyperV\ISOs" -ItemType Directory -Force

# Download Ubuntu 22.04 Desktop
$ubuntuUrl = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
$isoPath = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"

# Download (or just download via browser and save to C:\HyperV\ISOs\)
Start-BitsTransfer -Source $ubuntuUrl -Destination $isoPath
```

```powershell
# Create VM for ISO building
$vmName = "MediaBox-Builder"
$vmPath = "C:\HyperV\VMs"
$isoPath = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"

# Create directories
New-Item -Path $vmPath -ItemType Directory -Force

# Create VM with optimal settings
New-VM -Name $vmName `
    -MemoryStartupBytes 8GB `
    -Generation 2 `
    -NewVHDPath "$vmPath\$vmName.vhdx" `
    -NewVHDSizeBytes 60GB `
    -SwitchName "MediaBox-Network"

# Configure VM
Set-VM -Name $vmName `
    -ProcessorCount 4 `
    -DynamicMemory `
    -MemoryMinimumBytes 4GB `
    -MemoryMaximumBytes 8GB `
    -AutomaticCheckpointsEnabled $false

# Disable Secure Boot (required for Ubuntu)
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Add DVD drive with Ubuntu ISO
Add-VMDvdDrive -VMName $vmName -Path $isoPath

# Set DVD as first boot device
$dvd = Get-VMDvdDrive -VMName $vmName
Set-VMFirmware -VMName $vmName -FirstBootDevice $dvd

# Enable Enhanced Session (better clipboard/resolution)
Set-VM -VMName $vmName -EnhancedSessionTransportType HvSocket

Write-Host "✅ VM Created: $vmName" -ForegroundColor Green
Write-Host "📀 Boot from: $isoPath" -ForegroundColor Cyan
Write-Host "🚀 Start VM in Hyper-V Manager" -ForegroundColor Yellow
```

```shellscript
# Update system
sudo apt update && sudo apt upgrade -y

# Install Hyper-V guest tools (Enhanced Session support)
sudo apt install -y linux-tools-virtual linux-cloud-tools-virtual

# Enable Enhanced Session
sudo nano /etc/xrdp/xrdp.ini
# Change: port=3389 to port=vsock://-1:3389
# Save and exit

sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Reboot VM
sudo reboot
```

```shellscript
# Install Cubic
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Create workspace
mkdir -p ~/mediabox-iso-builds
cd ~/mediabox-iso-builds

# Copy your MediaBox files
# Option 1: Clone from Git
git clone <YOUR_GIT_REPO> mediabox-source

# Option 2: Copy from Windows using shared folder (see below)
```

```powershell
# Share your MediaBox folder
$sharePath = "C:\Users\chris\@TVBOX\mediabox-dev"
New-SmbShare -Name "mediabox" -Path $sharePath -FullAccess "Everyone"

# Note your Windows IP
ipconfig | findstr IPv4
```

```shellscript
# Install CIFS utilities
sudo apt install -y cifs-utils

# Create mount point
sudo mkdir -p /mnt/windows-mediabox

# Mount Windows share (replace IP)
sudo mount -t cifs //YOUR_WINDOWS_IP/mediabox /mnt/windows-mediabox -o username=chris,vers=3.0

# Copy files
cp -r /mnt/windows-mediabox ~/mediabox-iso-builds/mediabox-source
```

```shellscript
# In Ubuntu VM
cd ~/mediabox-iso-builds
git clone https://github.com/yourusername/mediabox-ai.git mediabox-source
```

```powershell
# Create test VM (no ISO attached yet)
$testVMName = "MediaBox-Test"
$vmPath = "C:\HyperV\VMs"

New-VM -Name $testVMName `
    -MemoryStartupBytes 4GB `
    -Generation 2 `
    -NewVHDPath "$vmPath\$testVMName.vhdx" `
    -NewVHDSizeBytes 30GB `
    -SwitchName "MediaBox-Network"

Set-VM -Name $testVMName `
    -ProcessorCount 2 `
    -DynamicMemory `
    -MemoryMinimumBytes 2GB `
    -MemoryMaximumBytes 4GB `
    -AutomaticCheckpointsEnabled $true

# Disable Secure Boot
Set-VMFirmware -VMName $testVMName -EnableSecureBoot Off

# Add empty DVD drive (for your custom ISO later)
Add-VMDvdDrive -VMName $testVMName

Write-Host "✅ Test VM Created: $testVMName" -ForegroundColor Green
Write-Host "📀 Attach your MediaBox ISO when ready" -ForegroundColor Cyan
```

```plaintext
Windows 10 (Hyper-V Host)
    ↓
MediaBox-Builder VM (Ubuntu 22.04)
    ↓
1. Access MediaBox files (via SMB or Git)
2. Launch Cubic
3. Build custom ISO
4. Save ISO to shared location
```

```plaintext
Windows 10 (Hyper-V Host)
    ↓
MediaBox-Test VM (empty)
    ↓
1. Attach MediaBox ISO to DVD drive
2. Boot VM
3. Test installation
4. Test auto-start, kiosk mode
5. Create checkpoint if successful
6. Reset and test again
```

```powershell
# Create checkpoint before testing
Checkpoint-VM -Name "MediaBox-Test" -SnapshotName "Before-ISO-Test"

# Restore checkpoint
Restore-VMCheckpoint -Name "Before-ISO-Test" -VMName "MediaBox-Test" -Confirm:$false

# Delete checkpoint
Remove-VMCheckpoint -VMName "MediaBox-Test" -Name "Before-ISO-Test"
```

```powershell
# After building ISO in Builder VM, copy to Windows
# Then attach to Test VM
$isoPath = "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"
Set-VMDvdDrive -VMName "MediaBox-Test" -Path $isoPath

# Set boot order to DVD first
$dvd = Get-VMDvdDrive -VMName "MediaBox-Test"
Set-VMFirmware -VMName "MediaBox-Test" -FirstBootDevice $dvd
```

```powershell
# Start VMs
Start-VM -Name "MediaBox-Builder"
Start-VM -Name "MediaBox-Test"

# Stop VMs
Stop-VM -Name "MediaBox-Builder"
Stop-VM -Name "MediaBox-Test" -Force

# Connect to VM
vmconnect.exe localhost "MediaBox-Builder"

# Get VM status
Get-VM | Format-Table Name, State, CPUUsage, MemoryAssigned
```

```powershell
#Requires -RunAsAdministrator
# MediaBox AI - Hyper-V Setup Script

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI - Hyper-V Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$vmPath = "C:\HyperV\VMs"
$isoPath = "C:\HyperV\ISOs"
$ubuntuISO = "$isoPath\ubuntu-22.04.3-desktop-amd64.iso"
$switchName = "MediaBox-Network"

# Create directories
Write-Host "[1/5] Creating directories..." -ForegroundColor Green
New-Item -Path $vmPath -ItemType Directory -Force | Out-Null
New-Item -Path $isoPath -ItemType Directory -Force | Out-Null

# Create virtual switch if it doesn't exist
Write-Host "[2/5] Creating virtual switch..." -ForegroundColor Green
if (!(Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue)) {
    $netAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    New-VMSwitch -Name $switchName -NetAdapterName $netAdapter.Name -AllowManagementOS $true
    Write-Host "✅ Virtual switch created: $switchName" -ForegroundColor Green
} else {
    Write-Host "✅ Virtual switch already exists: $switchName" -ForegroundColor Yellow
}

# Check for Ubuntu ISO
Write-Host "[3/5] Checking Ubuntu ISO..." -ForegroundColor Green
if (!(Test-Path $ubuntuISO)) {
    Write-Host "⚠️  Ubuntu ISO not found!" -ForegroundColor Red
    Write-Host "Please download Ubuntu 22.04 Desktop ISO and save to:" -ForegroundColor Yellow
    Write-Host "  $ubuntuISO" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Download from: https://releases.ubuntu.com/22.04/" -ForegroundColor Cyan
    exit
}

# Create Builder VM
Write-Host "[4/5] Creating MediaBox-Builder VM..." -ForegroundColor Green
$builderName = "MediaBox-Builder"
if (Get-VM -Name $builderName -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  VM already exists: $builderName" -ForegroundColor Yellow
} else {
    New-VM -Name $builderName `
        -MemoryStartupBytes 8GB `
        -Generation 2 `
        -NewVHDPath "$vmPath\$builderName.vhdx" `
        -NewVHDSizeBytes 60GB `
        -SwitchName $switchName
    
    Set-VM -Name $builderName `
        -ProcessorCount 4 `
        -DynamicMemory `
        -MemoryMinimumBytes 4GB `
        -MemoryMaximumBytes 8GB `
        -AutomaticCheckpointsEnabled $false
    
    Set-VMFirmware -VMName $builderName -EnableSecureBoot Off
    Add-VMDvdDrive -VMName $builderName -Path $ubuntuISO
    
    $dvd = Get-VMDvdDrive -VMName $builderName
    Set-VMFirmware -VMName $builderName -FirstBootDevice $dvd
    
    Write-Host "✅ Created: $builderName" -ForegroundColor Green
}

# Create Test VM
Write-Host "[5/5] Creating MediaBox-Test VM..." -ForegroundColor Green
$testName = "MediaBox-Test"
if (Get-VM -Name $testName -ErrorAction SilentlyContinue) {
    Write-Host "⚠️  VM already exists: $testName" -ForegroundColor Yellow
} else {
    New-VM -Name $testName `
        -MemoryStartupBytes 4GB `
        -Generation 2 `
        -NewVHDPath "$vmPath\$testName.vhdx" `
        -NewVHDSizeBytes 30GB `
        -SwitchName $switchName
    
    Set-VM -Name $testName `
        -ProcessorCount 2 `
        -DynamicMemory `
        -MemoryMinimumBytes 2GB `
        -MemoryMaximumBytes 4GB `
        -AutomaticCheckpointsEnabled $true
    
    Set-VMFirmware -VMName $testName -EnableSecureBoot Off
    Add-VMDvdDrive -VMName $testName
    
    Write-Host "✅ Created: $testName" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start MediaBox-Builder VM" -ForegroundColor White
Write-Host "   Start-VM -Name 'MediaBox-Builder'" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Install Ubuntu 22.04 in Builder VM" -ForegroundColor White
Write-Host "   - Choose 'Minimal Installation'" -ForegroundColor Gray
Write-Host "   - Install Cubic after first boot" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Build your MediaBox ISO in Cubic" -ForegroundColor White
Write-Host ""
Write-Host "4. Test ISO in MediaBox-Test VM" -ForegroundColor White
Write-Host "   Set-VMDvdDrive -VMName 'MediaBox-Test' -Path 'path\to\your.iso'" -ForegroundColor Gray
Write-Host ""
```

```powershell
# Save the script, then:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Setup-MediaBoxHyperV.ps1
```

---

**User**

given im using cursor with wsl2  what ar the advantages/disadvantages of creating the ISO here

---

**Cursor**

Excellent question! Since you're **already using WSL2 with Cursor**, this changes everything. Let me analyze whether building the ISO in WSL2 vs a Hyper-V VM makes sense.

---

## **🔍 WSL2 vs HYPER-V VM FOR ISO BUILDING**

### **Current Situation:**
```
Your Setup:
├── Windows 10 Pro
├── Hyper-V (enabled)
├── WSL2 (Ubuntu - already running for Cursor)
│   └── Your MediaBox files at /mnt/c/Users/chris/@TVBOX/mediabox-dev
└── Cursor IDE (editing via WSL2)
```

---

## **✅ ADVANTAGES of Building ISO in WSL2**

### **1. Already Set Up**
```bash
# You already have Ubuntu running
wsl -l -v
# Your files are already accessible
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev
```
- ✅ No need to create separate VM
- ✅ No need to transfer files
- ✅ Direct access to Windows filesystem
- ✅ Same environment where you're developing

### **2. Seamless File Access**
```bash
# WSL2 can directly access Windows files
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev

# And Windows can access WSL2 files
# \\wsl$\Ubuntu\home\chris\
```
- ✅ No SMB shares needed
- ✅ No file copying between VM and host
- ✅ Edit in Cursor → Build immediately in WSL2

### **3. Better Integration**
- ✅ Same terminal you're already using
- ✅ Git repos are already cloned
- ✅ Python environment already set up
- ✅ No VM startup time

### **4. Resource Efficient**
- ✅ WSL2 uses less RAM (dynamic allocation)
- ✅ Only one Ubuntu instance running
- ✅ No duplicate packages/tools

---

## **❌ DISADVANTAGES of Building ISO in WSL2**

### **1. Cubic Requires GUI** (Big Challenge)

Cubic is a GUI application. WSL2 doesn't have a GUI by default.

**You need an X Server:**
```powershell
# Install VcXsrv or X410 on Windows
winget install vcxsrv
# Or: winget install X410
```

**Then in WSL2:**
```bash
# Set DISPLAY variable
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0

# Test with simple GUI app
sudo apt install x11-apps
xclock  # If this works, Cubic will work
```

**Complexity:** Medium (one-time setup)

### **2. WSL2 Limitations for ISO Building**

Some tools Cubic uses may have issues:

```bash
# Check WSL2 version
wsl --version

# WSL2 doesn't have full systemd by default (Ubuntu 22.04+ fixes this)
# But you don't need systemd to BUILD an ISO, only to TEST it
```

**Workaround:** Build in WSL2, test in Hyper-V VM (best of both worlds!)

### **3. Loop Device / Mount Issues**

Cubic needs to mount ISO images and filesystem images:

```bash
# WSL2 may have limited loop device support
sudo losetup -f  # Check if loop devices available

# May need to enable in .wslconfig
```

**In Windows:** `C:\Users\chris\.wslconfig`
```ini
[wsl2]
kernelCommandLine = systemd.unified_cgroup_hierarchy=0
nestedVirtualization=true
```

---

## **🎯 MY RECOMMENDATION: HYBRID APPROACH** ⭐

Use **WSL2 for development & building**, **Hyper-V VM for testing**:

```
Your Optimal Workflow:

1. DEVELOP (WSL2 + Cursor)
   ├── Edit files in Cursor
   ├── Test Python scripts in WSL2
   └── Git commits from WSL2

2. BUILD ISO (WSL2 + Cubic with X Server)
   ├── Install X Server on Windows
   ├── Run Cubic in WSL2
   ├── Build ISO
   └── Save ISO to Windows filesystem

3. TEST ISO (Hyper-V VM)
   ├── Create test VM in Hyper-V
   ├── Mount your custom ISO
   ├── Test boot/install
   └── Use checkpoints for multiple tests
```

---

## **📋 SETUP GUIDE: WSL2 + CUBIC**

### **Step 1: Verify Your WSL2 Setup**

```powershell
# In Windows PowerShell
wsl --version
wsl -l -v

# Make sure you have WSL version 2
# NAME          STATE           VERSION
# * Ubuntu      Running         2
```

### **Step 2: Install X Server on Windows**

**Option A: VcXsrv (Free, Open Source)**
```powershell
winget install vcxsrv
```

**Launch VcXsrv:**
1. Start Menu → XLaunch
2. Multiple windows → Next
3. Start no client → Next
4. ✅ **Disable access control** (important!)
5. Save configuration → Finish

**Option B: X410 (Paid, Better Performance)**
```powershell
# From Microsoft Store ($9.99)
# Search for "X410"
```

### **Step 3: Configure WSL2 for GUI Apps**

**In WSL2:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install X11 dependencies
sudo apt install -y \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    dbus-x11

# Add to ~/.bashrc for automatic DISPLAY setup
cat >> ~/.bashrc << 'EOF'

# X Server for GUI apps
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1
EOF

# Reload
source ~/.bashrc

# Test GUI
xclock &  # Should show a clock window on Windows
```

**If xclock works, you're good to go!** ✅

### **Step 4: Install Cubic in WSL2**

```bash
# In WSL2
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Verify installation
cubic --version
```

### **Step 5: Launch Cubic from WSL2**

```bash
# Navigate to your MediaBox directory
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev

# Create ISO build directory
mkdir -p ~/mediabox-iso-builds

# Launch Cubic (GUI will appear on Windows desktop)
cubic &
```

**Cubic should launch as a Windows window!** 🎉

### **Step 6: Build ISO in Cubic**

Follow the normal Cubic workflow:
1. Project directory: `/home/chris/mediabox-iso-builds`
2. Source ISO: Download Ubuntu ISO to `/mnt/c/HyperV/ISOs/`
3. Customize in chroot terminal
4. Generate ISO
5. **Save ISO to**: `/mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso`
   - This makes it accessible from Windows at `C:\HyperV\ISOs\`

### **Step 7: Test ISO in Hyper-V VM**

```powershell
# In Windows PowerShell
# Attach ISO to test VM
Set-VMDvdDrive -VMName "MediaBox-Test" -Path "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"

# Start test VM
Start-VM -Name "MediaBox-Test"
```

---

## **⚡ COMPARISON TABLE**

| Aspect | WSL2 + X Server | Hyper-V Ubuntu VM |
|--------|-----------------|-------------------|
| **Setup Complexity** | Medium (X server) | Low (standard VM) |
| **File Access** | ⭐⭐⭐⭐⭐ Direct | ⭐⭐⭐ SMB/Copy |
| **Performance** | ⭐⭐⭐⭐ Fast | ⭐⭐⭐⭐ Fast |
| **RAM Usage** | ⭐⭐⭐⭐⭐ Efficient | ⭐⭐⭐ Fixed allocation |
| **Cursor Integration** | ⭐⭐⭐⭐⭐ Native | ⭐⭐ Remote |
| **GUI Stability** | ⭐⭐⭐ (X forwarding) | ⭐⭐⭐⭐⭐ Native |
| **ISO Testing** | ❌ Can't test boots | ✅ Full boot testing |
| **Already Set Up** | ✅ You have this | ❌ Need to create |

---

## **🎯 DECISION MATRIX**

### **Use WSL2 if:**
- ✅ You want to stay in your current workflow
- ✅ You don't mind setting up X server (one-time)
- ✅ You want fastest file access
- ✅ You're comfortable with Linux command line
- ✅ You want to integrate with Cursor/Git workflow

### **Use Hyper-V VM if:**
- ✅ You want pure GUI experience (no X forwarding)
- ✅ You want the most "standard" setup
- ✅ You don't want to troubleshoot X server issues
- ✅ You prefer clicking vs typing commands

---

## **💡 MY ACTUAL RECOMMENDATION FOR YOU**

Since you're **already using WSL2 + Cursor**:

### **Optimal Setup:**

```
┌─────────────────────────────────────────────┐
│ Windows 10 Pro                              │
│                                             │
│  ┌─────────────────┐    ┌─────────────────┐│
│  │ WSL2 (Ubuntu)   │    │ Hyper-V VM      ││
│  │                 │    │ (MediaBox-Test) ││
│  │ • Cursor/VS Code│    │                 ││
│  │ • Git           │    │ • ISO Testing   ││
│  │ • MediaBox Code │    │ • Boot Testing  ││
│  │ • Cubic + ISO   │    │ • Checkpoints   ││
│  │   Building      │    │                 ││
│  └─────────────────┘    └─────────────────┘│
│         ↓                       ↑           │
│     Build ISO              Test ISO         │
│         ↓                       ↑           │
│  C:\HyperV\ISOs\mediabox-ai-v1.0.iso       │
└─────────────────────────────────────────────┘
```

### **Workflow:**

```bash
# 1. DEVELOP in WSL2 (where you already work)
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev
# Edit in Cursor, test scripts, commit to git

# 2. BUILD ISO in WSL2 with Cubic
cubic &  # GUI appears on Windows via X server

# 3. TEST ISO in Hyper-V VM
# (In PowerShell)
Set-VMDvdDrive -VMName "MediaBox-Test" -Path "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"
Start-VM -Name "MediaBox-Test"
```

---

## **🚀 QUICK START: WSL2 APPROACH**

```bash
# In WSL2 (where you already have Cursor working)

# 1. Install X dependencies
sudo apt install -y x11-apps

# 2. Set DISPLAY
echo 'export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '"'"'{print $2}'"'"'):0' >> ~/.bashrc
source ~/.bashrc

# 3. Install Cubic
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# 4. Create workspace
mkdir -p ~/mediabox-iso-builds

# 5. Launch Cubic
cubic &
```

**In Windows:** Launch VcXsrv first (XLaunch from Start Menu)

---

## **✅ FINAL ANSWER**

**Use WSL2 for ISO building** because:
1. ✅ You're already there with Cursor
2. ✅ Direct access to your files
3. ✅ One-time X server setup (15 min)
4. ✅ Faster iteration (edit → build)
5. ✅ Keep Hyper-V for testing VMs only

**Total setup time:** ~20 minutes to get Cubic working in WSL2

Want me to provide a **complete WSL2 + Cubic setup script** you can run right now?

```plaintext
Your Setup:
├── Windows 10 Pro
├── Hyper-V (enabled)
├── WSL2 (Ubuntu - already running for Cursor)
│   └── Your MediaBox files at /mnt/c/Users/chris/@TVBOX/mediabox-dev
└── Cursor IDE (editing via WSL2)
```

```shellscript
# You already have Ubuntu running
wsl -l -v
# Your files are already accessible
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev
```

```shellscript
# WSL2 can directly access Windows files
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev

# And Windows can access WSL2 files
# \\wsl$\Ubuntu\home\chris\
```

```powershell
# Install VcXsrv or X410 on Windows
winget install vcxsrv
# Or: winget install X410
```

```shellscript
# Set DISPLAY variable
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0

# Test with simple GUI app
sudo apt install x11-apps
xclock  # If this works, Cubic will work
```

```shellscript
# Check WSL2 version
wsl --version

# WSL2 doesn't have full systemd by default (Ubuntu 22.04+ fixes this)
# But you don't need systemd to BUILD an ISO, only to TEST it
```

```shellscript
# WSL2 may have limited loop device support
sudo losetup -f  # Check if loop devices available

# May need to enable in .wslconfig
```

```ini
[wsl2]
kernelCommandLine = systemd.unified_cgroup_hierarchy=0
nestedVirtualization=true
```

```plaintext
Your Optimal Workflow:

1. DEVELOP (WSL2 + Cursor)
   ├── Edit files in Cursor
   ├── Test Python scripts in WSL2
   └── Git commits from WSL2

2. BUILD ISO (WSL2 + Cubic with X Server)
   ├── Install X Server on Windows
   ├── Run Cubic in WSL2
   ├── Build ISO
   └── Save ISO to Windows filesystem

3. TEST ISO (Hyper-V VM)
   ├── Create test VM in Hyper-V
   ├── Mount your custom ISO
   ├── Test boot/install
   └── Use checkpoints for multiple tests
```

```powershell
# In Windows PowerShell
wsl --version
wsl -l -v

# Make sure you have WSL version 2
# NAME          STATE           VERSION
# * Ubuntu      Running         2
```

```powershell
winget install vcxsrv
```

```powershell
# From Microsoft Store ($9.99)
# Search for "X410"
```

```shellscript
# Update system
sudo apt update && sudo apt upgrade -y

# Install X11 dependencies
sudo apt install -y \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    dbus-x11

# Add to ~/.bashrc for automatic DISPLAY setup
cat >> ~/.bashrc << 'EOF'

# X Server for GUI apps
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export LIBGL_ALWAYS_INDIRECT=1
EOF

# Reload
source ~/.bashrc

# Test GUI
xclock &  # Should show a clock window on Windows
```

```shellscript
# In WSL2
sudo apt-add-repository -y universe
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# Verify installation
cubic --version
```

```shellscript
# Navigate to your MediaBox directory
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev

# Create ISO build directory
mkdir -p ~/mediabox-iso-builds

# Launch Cubic (GUI will appear on Windows desktop)
cubic &
```

```powershell
# In Windows PowerShell
# Attach ISO to test VM
Set-VMDvdDrive -VMName "MediaBox-Test" -Path "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"

# Start test VM
Start-VM -Name "MediaBox-Test"
```

```plaintext
┌─────────────────────────────────────────────┐
│ Windows 10 Pro                              │
│                                             │
│  ┌─────────────────┐    ┌─────────────────┐│
│  │ WSL2 (Ubuntu)   │    │ Hyper-V VM      ││
│  │                 │    │ (MediaBox-Test) ││
│  │ • Cursor/VS Code│    │                 ││
│  │ • Git           │    │ • ISO Testing   ││
│  │ • MediaBox Code │    │ • Boot Testing  ││
│  │ • Cubic + ISO   │    │ • Checkpoints   ││
│  │   Building      │    │                 ││
│  └─────────────────┘    └─────────────────┘│
│         ↓                       ↑           │
│     Build ISO              Test ISO         │
│         ↓                       ↑           │
│  C:\HyperV\ISOs\mediabox-ai-v1.0.iso       │
└─────────────────────────────────────────────┘
```

```shellscript
# 1. DEVELOP in WSL2 (where you already work)
cd /mnt/c/Users/chris/@TVBOX/mediabox-dev
# Edit in Cursor, test scripts, commit to git

# 2. BUILD ISO in WSL2 with Cubic
cubic &  # GUI appears on Windows via X server

# 3. TEST ISO in Hyper-V VM
# (In PowerShell)
Set-VMDvdDrive -VMName "MediaBox-Test" -Path "C:\HyperV\ISOs\mediabox-ai-v1.0.iso"
Start-VM -Name "MediaBox-Test"
```

```shellscript
# In WSL2 (where you already have Cursor working)

# 1. Install X dependencies
sudo apt install -y x11-apps

# 2. Set DISPLAY
echo 'export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '"'"'{print $2}'"'"'):0' >> ~/.bashrc
source ~/.bashrc

# 3. Install Cubic
sudo apt-add-repository -y ppa:cubic-wizard/release
sudo apt update
sudo apt install -y cubic

# 4. Create workspace
mkdir -p ~/mediabox-iso-builds

# 5. Launch Cubic
cubic &
```

---

**User**

yes

---

**Cursor**

Perfect! Here's your complete setup package. I'll give you **3 scripts** to run in sequence.

---

## **🚀 COMPLETE WSL2 + CUBIC SETUP**

### **SCRIPT 1: Windows Setup (PowerShell)**

**Save as:** `Setup-WSL2-XServer.ps1`

```powershell
#Requires -RunAsAdministrator
# MediaBox AI - WSL2 X Server Setup for Cubic

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI - WSL2 X Server Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL2 is installed
Write-Host "[1/5] Checking WSL2..." -ForegroundColor Green
try {
    $wslVersion = wsl --version 2>$null
    Write-Host "✅ WSL2 is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL2 not found!" -ForegroundColor Red
    Write-Host "Please install WSL2 first: wsl --install" -ForegroundColor Yellow
    exit 1
}

# Check if Ubuntu is installed in WSL2
Write-Host "[2/5] Checking Ubuntu in WSL2..." -ForegroundColor Green
$wslList = wsl -l -v
if ($wslList -match "Ubuntu") {
    Write-Host "✅ Ubuntu found in WSL2" -ForegroundColor Green
} else {
    Write-Host "❌ Ubuntu not found in WSL2!" -ForegroundColor Red
    Write-Host "Install with: wsl --install -d Ubuntu" -ForegroundColor Yellow
    exit 1
}

# Install VcXsrv (X Server)
Write-Host "[3/5] Installing VcXsrv X Server..." -ForegroundColor Green
try {
    $vcxsrv = Get-Command vcxsrv -ErrorAction SilentlyContinue
    if ($vcxsrv) {
        Write-Host "✅ VcXsrv already installed" -ForegroundColor Yellow
    } else {
        Write-Host "Installing VcXsrv via winget..." -ForegroundColor Cyan
        winget install --id marha.VcXsrv --silent --accept-package-agreements --accept-source-agreements
        Write-Host "✅ VcXsrv installed" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Automatic install failed. Please install manually:" -ForegroundColor Yellow
    Write-Host "   Download: https://sourceforge.net/projects/vcxsrv/" -ForegroundColor Cyan
}

# Create VcXsrv config file
Write-Host "[4/5] Creating VcXsrv configuration..." -ForegroundColor Green
$vcxsrvConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<XLaunch WindowMode="MultiWindow" ClientMode="NoClient" LocalClient="False" Display="0" 
         LocalProgram="xcalc" RemoteProgram="xterm" RemotePassword="" PrivateKey="" 
         RemoteHost="" RemoteUser="" XDMCPHost="" XDMCPBroadcast="False" 
         XDMCPIndirect="False" Clipboard="True" ClipboardPrimary="True" 
         ExtraParams="-ac" Wgl="True" DisableAC="True" XDMCPTerminate="False"/>
"@

$configPath = "$env:APPDATA\Xlaunch"
New-Item -Path $configPath -ItemType Directory -Force | Out-Null
$vcxsrvConfig | Out-File "$configPath\mediabox.xlaunch" -Encoding UTF8

Write-Host "✅ Configuration saved: $configPath\mediabox.xlaunch" -ForegroundColor Green

# Create startup script
Write-Host "[5/5] Creating VcXsrv launcher..." -ForegroundColor Green
$launcherScript = @"
@echo off
REM MediaBox AI - VcXsrv Launcher
echo Starting VcXsrv X Server for WSL2...
start "" "C:\Program Files\VcXsrv\vcxsrv.exe" :0 -multiwindow -clipboard -wgl -ac -silent-dup-error
echo VcXsrv started successfully!
echo You can now run GUI apps in WSL2
timeout /t 3
"@

$launcherPath = "$env:USERPROFILE\Desktop\Start-XServer.bat"
$launcherScript | Out-File $launcherPath -Encoding ASCII

Write-Host "✅ Launcher created: $launcherPath" -ForegroundColor Green

# Create ISO directories
Write-Host "[BONUS] Creating ISO directories..." -ForegroundColor Green
$isoDir = "C:\HyperV\ISOs"
New-Item -Path $isoDir -ItemType Directory -Force | Out-Null
Write-Host "✅ Created: $isoDir" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Windows Setup Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start X Server: Double-click" -ForegroundColor White
Write-Host "   $launcherPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. In WSL2, run the Ubuntu setup script" -ForegroundColor White
Write-Host ""
Write-Host "📌 X Server will appear in system tray when running" -ForegroundColor Gray
Write-Host ""
```

---

### **SCRIPT 2: WSL2 Ubuntu Setup**

**Save as:** `setup-cubic-wsl2.sh` (in WSL2)

```bash
#!/bin/bash
# MediaBox AI - WSL2 Cubic Setup Script

set -e

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
    echo -e "${RED}❌ This script must run in WSL2!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Running in WSL2${NC}"
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

echo -e "${GREEN}✅ DISPLAY configured: $DISPLAY${NC}"

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
        echo "✅ SUCCESS! X Server is working!"
        echo "You should see a clock on your Windows desktop"
        echo ""
        echo "Closing test window..."
        kill $CLOCK_PID 2>/dev/null
    else
        echo "❌ FAILED! X Server not responding"
        echo ""
        echo "Troubleshooting:"
        echo "1. Make sure VcXsrv is running on Windows"
        echo "2. Check Windows Firewall settings"
        echo "3. Try: export DISPLAY=<windows-ip>:0"
    fi
else
    echo "❌ xclock not installed"
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
    echo "❌ MediaBox source not found: $MEDIABOX_SRC"
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
```

---

### **SCRIPT 3: Complete Workflow Helper**

**Save as:** `mediabox-iso-workflow.sh` (in WSL2)

```bash
#!/bin/bash
# MediaBox AI - Complete ISO Building Workflow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  MediaBox AI - ISO Builder Workflow${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Configuration
MEDIABOX_SRC="/mnt/c/Users/chris/@TVBOX/mediabox-dev"
UBUNTU_ISO="/mnt/c/HyperV/ISOs/ubuntu-22.04.3-desktop-amd64.iso"
OUTPUT_ISO="/mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso"
WORKSPACE="$HOME/mediabox-iso-builds"

# Check X Server
echo -e "${BLUE}[CHECK]${NC} Testing X Server connection..."
if xset q &>/dev/null; then
    echo -e "${GREEN}✅ X Server is running${NC}"
else
    echo -e "${RED}❌ X Server not responding!${NC}"
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
    echo -e "${YELLOW}⚠️  Ubuntu ISO not found!${NC}"
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
echo -e "${GREEN}✅ Ubuntu ISO found${NC}"

# Check MediaBox source
echo -e "${BLUE}[CHECK]${NC} Checking MediaBox source files..."
if [ ! -d "$MEDIABOX_SRC" ]; then
    echo -e "${RED}❌ MediaBox source not found: $MEDIABOX_SRC${NC}"
    exit 1
fi
echo -e "${GREEN}✅ MediaBox source found${NC}"

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
        echo -e "${YELLOW}📋 Cubic Workflow Reminder:${NC}"
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

========================================
  CUBIC QUICK GUIDE
========================================

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

# Install minimal X/window manager
apt install -y xorg openbox lightdm unclutter

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
  In Cubic, click "Options" → "Open Terminal"
  Run: cp -r /mnt/c/Users/chris/@TVBOX/mediabox-dev /opt/mediabox/

STEP 5: GENERATE ISO
  - Click "Next" through boot options
  - Generate ISO
  - Save to: /mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso

DONE! Test in Hyper-V VM

========================================
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
```

---

## **🎯 COMPLETE INSTALLATION PROCEDURE**

### **Phase 1: Windows Setup (5 minutes)**

```powershell
# In PowerShell (Run as Administrator)
cd C:\Users\chris\@TVBOX\mediabox-dev

# Save the first script, then run it
.\Setup-WSL2-XServer.ps1

# Start X Server from desktop
# Double-click: Start-XServer.bat
```

### **Phase 2: WSL2 Setup (10 minutes)**

```bash
# In WSL2 terminal
cd ~

# Create and run the setup script
nano setup-cubic-wsl2.sh
# Paste Script 2, save (Ctrl+O, Enter, Ctrl+X)

chmod +x setup-cubic-wsl2.sh
./setup-cubic-wsl2.sh

# Reload shell
source ~/.bashrc
```

### **Phase 3: Test X Server (1 minute)**

```bash
# In WSL2
~/test-x-server.sh

# Should show a clock window on Windows desktop
```

### **Phase 4: Download Ubuntu ISO**

```powershell
# In Windows PowerShell or Browser
# Download to: C:\HyperV\ISOs\

# Via PowerShell:
$url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
$output = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"
Start-BitsTransfer -Source $url -Destination $output
```

### **Phase 5: Build ISO (30-60 minutes)**

```bash
# In WSL2
~/mediabox-iso-workflow.sh

# Select option 1 to launch Cubic
# Follow the on-screen guide
```

---

## **📝 QUICK REFERENCE CARD**

Save this for future use:

```bash
# Start X Server (Windows)
Start-XServer.bat (on Desktop)

# Test X connection (WSL2)
~/test-x-server.sh

# Launch Cubic (WSL2)
~/launch-cubic.sh

# Complete workflow (WSL2)
~/mediabox-iso-workflow.sh

# Workspace location
~/mediabox-iso-builds/

# Output ISOs
/mnt/c/HyperV/ISOs/  →  C:\HyperV\ISOs\ (Windows)
```

---

## **🎮 TO USE RIGHT NOW**

1. **Copy Script 1** → Save as `Setup-WSL2-XServer.ps1` on Windows
2. **Run in PowerShell (Admin):** `.\Setup-WSL2-XServer.ps1`
3. **Start X Server** from desktop shortcut
4. **Copy Script 2** → Save in WSL2 as `~/setup-cubic-wsl2.sh`
5. **Run in WSL2:** `bash ~/setup-cubic-wsl2.sh`
6. **Test:** `~/test-x-server.sh`
7. **Build ISO:** `~/launch-cubic.sh`

**Total setup time:** 15-20 minutes
**Then you're ready to build ISOs!** 🚀

Need me to clarify any step?

```powershell
#Requires -RunAsAdministrator
# MediaBox AI - WSL2 X Server Setup for Cubic

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  MediaBox AI - WSL2 X Server Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if WSL2 is installed
Write-Host "[1/5] Checking WSL2..." -ForegroundColor Green
try {
    $wslVersion = wsl --version 2>$null
    Write-Host "✅ WSL2 is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL2 not found!" -ForegroundColor Red
    Write-Host "Please install WSL2 first: wsl --install" -ForegroundColor Yellow
    exit 1
}

# Check if Ubuntu is installed in WSL2
Write-Host "[2/5] Checking Ubuntu in WSL2..." -ForegroundColor Green
$wslList = wsl -l -v
if ($wslList -match "Ubuntu") {
    Write-Host "✅ Ubuntu found in WSL2" -ForegroundColor Green
} else {
    Write-Host "❌ Ubuntu not found in WSL2!" -ForegroundColor Red
    Write-Host "Install with: wsl --install -d Ubuntu" -ForegroundColor Yellow
    exit 1
}

# Install VcXsrv (X Server)
Write-Host "[3/5] Installing VcXsrv X Server..." -ForegroundColor Green
try {
    $vcxsrv = Get-Command vcxsrv -ErrorAction SilentlyContinue
    if ($vcxsrv) {
        Write-Host "✅ VcXsrv already installed" -ForegroundColor Yellow
    } else {
        Write-Host "Installing VcXsrv via winget..." -ForegroundColor Cyan
        winget install --id marha.VcXsrv --silent --accept-package-agreements --accept-source-agreements
        Write-Host "✅ VcXsrv installed" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Automatic install failed. Please install manually:" -ForegroundColor Yellow
    Write-Host "   Download: https://sourceforge.net/projects/vcxsrv/" -ForegroundColor Cyan
}

# Create VcXsrv config file
Write-Host "[4/5] Creating VcXsrv configuration..." -ForegroundColor Green
$vcxsrvConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<XLaunch WindowMode="MultiWindow" ClientMode="NoClient" LocalClient="False" Display="0" 
         LocalProgram="xcalc" RemoteProgram="xterm" RemotePassword="" PrivateKey="" 
         RemoteHost="" RemoteUser="" XDMCPHost="" XDMCPBroadcast="False" 
         XDMCPIndirect="False" Clipboard="True" ClipboardPrimary="True" 
         ExtraParams="-ac" Wgl="True" DisableAC="True" XDMCPTerminate="False"/>
"@

$configPath = "$env:APPDATA\Xlaunch"
New-Item -Path $configPath -ItemType Directory -Force | Out-Null
$vcxsrvConfig | Out-File "$configPath\mediabox.xlaunch" -Encoding UTF8

Write-Host "✅ Configuration saved: $configPath\mediabox.xlaunch" -ForegroundColor Green

# Create startup script
Write-Host "[5/5] Creating VcXsrv launcher..." -ForegroundColor Green
$launcherScript = @"
@echo off
REM MediaBox AI - VcXsrv Launcher
echo Starting VcXsrv X Server for WSL2...
start "" "C:\Program Files\VcXsrv\vcxsrv.exe" :0 -multiwindow -clipboard -wgl -ac -silent-dup-error
echo VcXsrv started successfully!
echo You can now run GUI apps in WSL2
timeout /t 3
"@

$launcherPath = "$env:USERPROFILE\Desktop\Start-XServer.bat"
$launcherScript | Out-File $launcherPath -Encoding ASCII

Write-Host "✅ Launcher created: $launcherPath" -ForegroundColor Green

# Create ISO directories
Write-Host "[BONUS] Creating ISO directories..." -ForegroundColor Green
$isoDir = "C:\HyperV\ISOs"
New-Item -Path $isoDir -ItemType Directory -Force | Out-Null
Write-Host "✅ Created: $isoDir" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Windows Setup Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Start X Server: Double-click" -ForegroundColor White
Write-Host "   $launcherPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. In WSL2, run the Ubuntu setup script" -ForegroundColor White
Write-Host ""
Write-Host "📌 X Server will appear in system tray when running" -ForegroundColor Gray
Write-Host ""
```

```shellscript
#!/bin/bash
# MediaBox AI - WSL2 Cubic Setup Script

set -e

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
    echo -e "${RED}❌ This script must run in WSL2!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Running in WSL2${NC}"
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

echo -e "${GREEN}✅ DISPLAY configured: $DISPLAY${NC}"

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
        echo "✅ SUCCESS! X Server is working!"
        echo "You should see a clock on your Windows desktop"
        echo ""
        echo "Closing test window..."
        kill $CLOCK_PID 2>/dev/null
    else
        echo "❌ FAILED! X Server not responding"
        echo ""
        echo "Troubleshooting:"
        echo "1. Make sure VcXsrv is running on Windows"
        echo "2. Check Windows Firewall settings"
        echo "3. Try: export DISPLAY=<windows-ip>:0"
    fi
else
    echo "❌ xclock not installed"
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
    echo "❌ MediaBox source not found: $MEDIABOX_SRC"
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
```

```shellscript
#!/bin/bash
# MediaBox AI - Complete ISO Building Workflow

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  MediaBox AI - ISO Builder Workflow${NC}"
echo -e "${CYAN}=========================================${NC}"
echo ""

# Configuration
MEDIABOX_SRC="/mnt/c/Users/chris/@TVBOX/mediabox-dev"
UBUNTU_ISO="/mnt/c/HyperV/ISOs/ubuntu-22.04.3-desktop-amd64.iso"
OUTPUT_ISO="/mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso"
WORKSPACE="$HOME/mediabox-iso-builds"

# Check X Server
echo -e "${BLUE}[CHECK]${NC} Testing X Server connection..."
if xset q &>/dev/null; then
    echo -e "${GREEN}✅ X Server is running${NC}"
else
    echo -e "${RED}❌ X Server not responding!${NC}"
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
    echo -e "${YELLOW}⚠️  Ubuntu ISO not found!${NC}"
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
echo -e "${GREEN}✅ Ubuntu ISO found${NC}"

# Check MediaBox source
echo -e "${BLUE}[CHECK]${NC} Checking MediaBox source files..."
if [ ! -d "$MEDIABOX_SRC" ]; then
    echo -e "${RED}❌ MediaBox source not found: $MEDIABOX_SRC${NC}"
    exit 1
fi
echo -e "${GREEN}✅ MediaBox source found${NC}"

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
        echo -e "${YELLOW}📋 Cubic Workflow Reminder:${NC}"
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

========================================
  CUBIC QUICK GUIDE
========================================

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

# Install minimal X/window manager
apt install -y xorg openbox lightdm unclutter

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
  In Cubic, click "Options" → "Open Terminal"
  Run: cp -r /mnt/c/Users/chris/@TVBOX/mediabox-dev /opt/mediabox/

STEP 5: GENERATE ISO
  - Click "Next" through boot options
  - Generate ISO
  - Save to: /mnt/c/HyperV/ISOs/mediabox-ai-v1.0.iso

DONE! Test in Hyper-V VM

========================================
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
```

```powershell
# In PowerShell (Run as Administrator)
cd C:\Users\chris\@TVBOX\mediabox-dev

# Save the first script, then run it
.\Setup-WSL2-XServer.ps1

# Start X Server from desktop
# Double-click: Start-XServer.bat
```

```shellscript
# In WSL2 terminal
cd ~

# Create and run the setup script
nano setup-cubic-wsl2.sh
# Paste Script 2, save (Ctrl+O, Enter, Ctrl+X)

chmod +x setup-cubic-wsl2.sh
./setup-cubic-wsl2.sh

# Reload shell
source ~/.bashrc
```

```shellscript
# In WSL2
~/test-x-server.sh

# Should show a clock window on Windows desktop
```

```powershell
# In Windows PowerShell or Browser
# Download to: C:\HyperV\ISOs\

# Via PowerShell:
$url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
$output = "C:\HyperV\ISOs\ubuntu-22.04.3-desktop-amd64.iso"
Start-BitsTransfer -Source $url -Destination $output
```

```shellscript
# In WSL2
~/mediabox-iso-workflow.sh

# Select option 1 to launch Cubic
# Follow the on-screen guide
```

```shellscript
# Start X Server (Windows)
Start-XServer.bat (on Desktop)

# Test X connection (WSL2)
~/test-x-server.sh

# Launch Cubic (WSL2)
~/launch-cubic.sh

# Complete workflow (WSL2)
~/mediabox-iso-workflow.sh

# Workspace location
~/mediabox-iso-builds/

# Output ISOs
/mnt/c/HyperV/ISOs/  →  C:\HyperV\ISOs\ (Windows)
```

