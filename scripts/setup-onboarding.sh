#!/bin/bash
echo "🔧 Setting up MediaBox AI environment..."

# Update package index and install core tools
sudo apt update
sudo apt install -y chromium-browser python3-pip x11vnc pavucontrol alsa-utils curl git     lirc ir-keytable input-utils docker-compose hypnotix

# Set up audio permissions
sudo usermod -aG audio $USER
sudo usermod -aG video $USER

# Set up autostart for dashboard API
sudo cp /home/mediabox/scripts/dashboard-api.service /etc/systemd/system/
sudo systemctl enable dashboard-api
sudo systemctl start dashboard-api

echo "✅ Setup complete. Reboot to apply all changes."
