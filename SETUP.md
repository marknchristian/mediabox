# MediaBox AI Setup Guide

This guide will help you set up MediaBox AI on your system.

## Prerequisites

- Ubuntu 22.04 or similar Linux distribution
- Python 3.8+
- PulseAudio
- Chromium browser
- X11 display server

## Installation Steps

### 1. Install System Dependencies

```bash
sudo apt update
sudo apt install -y \
  python3 \
  python3-pip \
  pulseaudio \
  pactl \
  pavucontrol \
  chromium-browser \
  xorg
```

### 2. Install Python Dependencies

```bash
cd mediabox-dev
pip3 install -r requirements.txt
```

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.py scripts/*.sh
```

### 4. Test Audio Switcher

```bash
# List available audio devices
./scripts/audio-switcher.py list

# Interactive mode
./scripts/audio-switcher.py
```

### 5. Test API Server

Start the API server:
```bash
python3 scripts/dashboard-api.py
```

In another terminal, test the endpoints:
```bash
# Check health
curl http://localhost:5000/api/health

# Get audio devices
curl http://localhost:5000/api/audio-devices

# Get status
curl http://localhost:5000/api/status
```

### 6. Launch Dashboard

```bash
# Option 1: Use the startup script
./scripts/start-dashboard.sh

# Option 2: Manual launch
python3 scripts/dashboard-api.py &
chromium-browser --app=file://$(pwd)/dashboard/index.html
```

## Auto-Start Configuration

### Enable API Server on Boot (Systemd)

```bash
# Copy service file
sudo cp scripts/mediabox-dashboard.service /etc/systemd/system/

# Update paths in service file if needed
sudo nano /etc/systemd/system/mediabox-dashboard.service

# Enable and start service
sudo systemctl enable mediabox-dashboard.service
sudo systemctl start mediabox-dashboard.service

# Check status
sudo systemctl status mediabox-dashboard.service
```

### Enable Dashboard on Login

Add to your `~/.config/autostart/mediabox.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=MediaBox AI Dashboard
Exec=/home/mediabox/scripts/start-dashboard.sh
X-GNOME-Autostart-enabled=true
```

## Docker Setup

### Build and Run

```bash
cd mediabox-dev
docker-compose up -d
```

### Access Container

```bash
docker exec -it mediabox-dev bash
```

### Inside Container

```bash
# Install dependencies
apt update
apt install -y python3-pip pulseaudio chromium-browser
pip3 install -r /home/mediabox/requirements.txt

# Start dashboard
cd /home/mediabox
./scripts/start-dashboard.sh
```

## Troubleshooting

### Audio Not Working

1. Check PulseAudio is running:
```bash
pulseaudio --check
```

2. List audio devices:
```bash
pactl list sinks short
```

3. Test audio:
```bash
speaker-test -t wav -c 2
```

### Dashboard Not Loading

1. Check API server is running:
```bash
curl http://localhost:5000/api/health
```

2. Check Chromium can access the file:
```bash
ls -l dashboard/index.html
```

3. Check for JavaScript errors in Chromium DevTools (F12)

### Permission Issues

Make sure scripts are executable:
```bash
chmod +x scripts/*.py scripts/*.sh
```

### Docker X11 Access Issues

Allow Docker to access X11:
```bash
xhost +local:docker
```

## IPTV Setup (Optional)

Install Hypnotix for Live TV:
```bash
sudo apt install hypnotix
```

Configure your M3U playlist in Hypnotix settings.

## Smart Home Setup (Optional)

### Install Home Assistant

Add to `docker-compose.yml`:
```yaml
  homeassistant:
    container_name: homeassistant
    image: homeassistant/home-assistant:stable
    volumes:
      - ./homeassistant:/config
    environment:
      - TZ=America/New_York
    restart: unless-stopped
    network_mode: host
```

Then access at http://localhost:8123

## Remote Control Setup

### KDE Connect

```bash
sudo apt install kdeconnect
```

Pair with your phone and use keyboard shortcuts from the mobile app.

### VNC Server

```bash
sudo apt install x11vnc
x11vnc -display :0 -auth guess -forever
```

Connect with bVNC or Remmina from your phone.

## Next Steps

- Configure your streaming service bookmarks
- Set up audio presets for different scenarios
- Customize the dashboard appearance
- Add IR remote control mapping
- Create custom API endpoints for specific needs

## Support

For issues and feature requests, refer to the project documentation or create an issue on GitHub.

