# MediaBox AI Docker Setup Guide

Complete Docker-based media center + smart home controller in one container.

## 🚀 Quick Start

### 1. Build the Container

```bash
chmod +x build.sh run.sh
./build.sh
```

Or manually:
```bash
docker build -t mediabox:latest .
```

### 2. Start the Container

```bash
./run.sh
```

Or manually:
```bash
docker-compose up -d
```

### 3. Access Services

- **Dashboard**: http://localhost:8080
- **Home Assistant**: http://localhost:8123
- **API Documentation**: http://localhost:8080/api/
- **Voice Control**: http://localhost:8081/voice/api/

## 📦 What's Included

### Services Running in Container

1. **Flask API Server** (Port 8080)
   - REST API for all controls
   - Serves HTML dashboard from `/`
   - Audio switching, volume control
   - System management

2. **Home Assistant** (Port 8123)
   - Smart home integration
   - Device control
   - Automation platform

3. **PulseAudio**
   - Audio routing and management
   - Multi-device support
   - Volume control

4. **Xvfb** (Virtual Display)
   - Headless X11 server
   - For running GUI apps

5. **Supervisor**
   - Process management
   - Auto-restart services
   - Centralized logging

### Scripts Available

- `audio-switcher.py` - Audio device management
- `dashboard-api.py` - Main Flask API server
- `iptv-launcher.py` - IPTV/Live TV support
- `voice-control-api.py` - Voice assistant (placeholder)
- `start-dashboard.sh` - Startup orchestration

## 🔧 Configuration

### Environment Variables

Set in `docker-compose.yml`:

```yaml
environment:
  - DISPLAY=:0
  - PULSE_SERVER=unix:/run/pulse/native
  - TZ=America/New_York
  - PORT=8080
```

### Volumes

- `./dashboard` → `/app/dashboard` - HTML dashboard
- `./scripts` → `/app/scripts` - Python scripts
- `./ha_config` → `/app/ha_config` - Home Assistant data (persistent)
- `/dev/snd` → Audio devices

### Ports

- `8080` - Flask Dashboard & API
- `8123` - Home Assistant
- `5900` - VNC (optional)

## 📡 API Endpoints

### Launch Services
```bash
# Launch Netflix
curl -X POST http://localhost:8080/api/launch/netflix

# Launch Plex
curl -X POST http://localhost:8080/api/launch/plex
```

### Audio Control
```bash
# List audio devices
curl http://localhost:8080/api/audio-devices

# Switch to HDMI
curl -X POST http://localhost:8080/api/switch-audio \
  -H "Content-Type: application/json" \
  -d '{"output": "hdmi"}'

# Set volume
curl -X POST http://localhost:8080/api/volume \
  -H "Content-Type: application/json" \
  -d '{"volume": 75}'
```

### System Control
```bash
# Get status
curl http://localhost:8080/api/status

# Health check
curl http://localhost:8080/api/health
```

## 🐳 Docker Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mediabox

# Supervisor logs (inside container)
docker exec mediabox-controller tail -f /var/log/supervisor/supervisord.log
```

### Shell Access
```bash
docker exec -it mediabox-controller bash
```

### Restart Services
```bash
# Restart container
docker-compose restart

# Restart specific service (inside container)
docker exec mediabox-controller supervisorctl restart flask-api
```

### Stop/Remove
```bash
# Stop
docker-compose stop

# Stop and remove
docker-compose down

# Remove with volumes
docker-compose down -v
```

## 🔊 Audio Setup

The container needs access to host audio devices.

### Linux Host

1. **Allow Docker access to PulseAudio:**
```bash
# Add to /etc/pulse/default.pa
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket
```

2. **Set environment variable:**
```bash
export PULSE_SERVER=unix:/tmp/pulse-socket
```

3. **Mount PulseAudio socket in docker-compose.yml:**
```yaml
volumes:
  - /tmp/pulse-socket:/tmp/pulse-socket
```

### macOS Host

Audio passthrough not directly supported. Use:
- Network audio streaming
- VNC/X11 forwarding to display on host

## 🏠 Home Assistant Setup

Home Assistant starts automatically in the container.

### First-Time Setup

1. Access http://localhost:8123
2. Create admin account
3. Configure integrations
4. Add devices

### Configuration

Persistent data stored in `./ha_config/`

Edit configuration:
```bash
# On host
nano ha_config/configuration.yaml

# Restart Home Assistant
docker exec mediabox-controller supervisorctl restart homeassistant
```

## 📺 IPTV Setup

### Add M3U Playlist

```bash
# Create IPTV directory in container
docker exec mediabox-controller mkdir -p ~/iptv

# Copy your M3U file
docker cp playlist.m3u mediabox-controller:/home/mediabox/iptv/

# Test launch
docker exec mediabox-controller python3 /app/scripts/iptv-launcher.py --vlc
```

### Use Web M3U

```bash
docker exec mediabox-controller python3 /app/scripts/iptv-launcher.py \
  --vlc --m3u "http://example.com/playlist.m3u"
```

## 🎤 Voice Control Setup

Voice control is currently a placeholder. See setup guide:

```bash
curl http://localhost:8081/voice/api/setup-guide | jq
```

### Recommended: voice2json + GPT

1. Install voice2json in container
2. Configure wake word
3. Add GPT API key
4. Map intents to MediaBox API calls

## 🔍 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Check if ports are in use
netstat -tuln | grep -E '8080|8123'

# Remove and rebuild
docker-compose down
./build.sh
./run.sh
```

### Audio Not Working

```bash
# Check PulseAudio in container
docker exec mediabox-controller pactl list sinks

# Test audio
docker exec mediabox-controller speaker-test -t wav -c 2

# Restart PulseAudio
docker exec mediabox-controller supervisorctl restart pulseaudio
```

### Home Assistant Not Accessible

```bash
# Check if running
docker exec mediabox-controller supervisorctl status homeassistant

# View logs
docker exec mediabox-controller tail -f /var/log/supervisor/homeassistant.log

# Restart
docker exec mediabox-controller supervisorctl restart homeassistant
```

### Dashboard Not Loading

```bash
# Check Flask is running
curl http://localhost:8080/api/health

# Check logs
docker exec mediabox-controller tail -f /var/log/supervisor/flask-api.log

# Restart Flask
docker exec mediabox-controller supervisorctl restart flask-api
```

## 🎯 Development

### Edit Files (Hot Reload)

Files are mounted as volumes, so changes are reflected immediately:

```bash
# Edit dashboard
nano dashboard/index.html
# Refresh browser

# Edit API
nano scripts/dashboard-api.py
# Restart Flask: docker exec mediabox-controller supervisorctl restart flask-api
```

### Add Python Packages

```bash
# Update requirements.txt
echo "new-package==1.0.0" >> requirements.txt

# Rebuild container
./build.sh
docker-compose up -d --force-recreate
```

### Debug Mode

Enable Flask debug mode:

```bash
docker exec mediabox-controller bash -c "export FLASK_DEBUG=1 && supervisorctl restart flask-api"
```

## 🚀 Production Deployment

### Systemd Auto-Start

Create `/etc/systemd/system/mediabox.service`:

```ini
[Unit]
Description=MediaBox Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/mediabox-dev
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
User=your-user

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl enable mediabox
sudo systemctl start mediabox
```

### Health Monitoring

Set up monitoring:

```bash
# Healthcheck script
#!/bin/bash
curl -f http://localhost:8080/api/health || docker-compose restart
```

Add to cron:
```bash
*/5 * * * * /path/to/healthcheck.sh
```

## 📝 Notes

- Container runs as non-root user `mediabox` for security
- Supervisor manages all services with auto-restart
- Logs available in `/var/log/supervisor/`
- PulseAudio runs in system mode for multi-user access
- Home Assistant data persists in `./ha_config/`

## 🆘 Support

For issues:
1. Check logs: `docker-compose logs`
2. Verify health: `curl http://localhost:8080/api/health`
3. Check supervisor: `docker exec mediabox-controller supervisorctl status`
4. Review this documentation

## 📚 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)
- [PulseAudio Wiki](https://www.freedesktop.org/wiki/Software/PulseAudio/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

