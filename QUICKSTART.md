# MediaBox AI Quick Start Guide

## 🎯 In 3 Commands

```bash
./build.sh          # Build Docker image
./run.sh            # Start all services
```

Then open: http://localhost:8080

## 📦 What You Get

✅ **Full Media Center Dashboard** - Netflix, Plex, Amazon, YouTube, Live TV  
✅ **Home Assistant** - Smart home control (port 8123)  
✅ **Audio Management** - Switch between HDMI, SPDIF, Analog  
✅ **REST API** - Full programmatic control  
✅ **IPTV Support** - VLC integration  
✅ **Voice Control Ready** - Placeholder + setup guide  

## 🏗️ Project Structure

```
mediabox-dev/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service orchestration
├── supervisord.conf        # Process manager config
├── requirements.txt        # Python dependencies
├── build.sh               # Build helper script
├── run.sh                 # Run helper script
│
├── dashboard/
│   └── index.html         # Beautiful web dashboard
│
├── scripts/
│   ├── dashboard-api.py   # Main Flask API (serves / and /api/*)
│   ├── audio-switcher.py  # Audio device management
│   ├── iptv-launcher.py   # IPTV/Live TV
│   ├── voice-control-api.py # Voice assistant (placeholder)
│   └── start-dashboard.sh # Startup script
│
├── ha_config/             # Home Assistant data (persistent)
│
└── DOCKER_README.md       # Detailed documentation
```

## 🚦 Service Ports

| Service | Port | URL |
|---------|------|-----|
| Dashboard & API | 8080 | http://localhost:8080 |
| Home Assistant | 8123 | http://localhost:8123 |
| Voice Control | 8081 | http://localhost:8081/voice/api/ |
| VNC (optional) | 5900 | vnc://localhost:5900 |

## 🎮 Usage Examples

### Dashboard
Open browser → http://localhost:8080
- Click buttons to launch services
- Switch audio output
- Control volume
- System power controls

### API Examples

```bash
# Health check
curl http://localhost:8080/api/health

# Launch Netflix
curl -X POST http://localhost:8080/api/launch/netflix

# Switch audio to HDMI
curl -X POST http://localhost:8080/api/switch-audio \
  -H "Content-Type: application/json" \
  -d '{"output":"hdmi"}'

# Set volume to 75%
curl -X POST http://localhost:8080/api/volume \
  -H "Content-Type: application/json" \
  -d '{"volume":75}'

# Get system status
curl http://localhost:8080/api/status

# List audio devices
curl http://localhost:8080/api/audio-devices
```

### CLI Tools (inside container)

```bash
# Enter container
docker exec -it mediabox-controller bash

# Audio management
python3 /app/scripts/audio-switcher.py list
python3 /app/scripts/audio-switcher.py switch --name hdmi
python3 /app/scripts/audio-switcher.py volume --set 50

# IPTV launcher
python3 /app/scripts/iptv-launcher.py --status
python3 /app/scripts/iptv-launcher.py --vlc
python3 /app/scripts/iptv-launcher.py --stream "http://example.com/stream.m3u"
```

## 🔍 Management Commands

```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop everything
docker-compose down

# Rebuild after changes
./build.sh && docker-compose up -d --force-recreate

# Shell access
docker exec -it mediabox-controller bash

# Check service status (inside container)
docker exec mediabox-controller supervisorctl status
```

## 🐛 Troubleshooting

### Container won't start
```bash
docker-compose logs
docker ps -a
```

### Dashboard not loading
```bash
curl http://localhost:8080/api/health
docker exec mediabox-controller supervisorctl status flask-api
```

### Audio not working
```bash
docker exec mediabox-controller pactl list sinks short
docker exec mediabox-controller python3 /app/scripts/audio-switcher.py list
```

### Home Assistant not accessible
```bash
curl http://localhost:8123
docker exec mediabox-controller supervisorctl status homeassistant
```

## ⚙️ Configuration

### Change Ports
Edit `docker-compose.yml`:
```yaml
ports:
  - "8080:8080"  # Change first number for host port
  - "8123:8123"
```

### Add Python Packages
Edit `requirements.txt`, then:
```bash
./build.sh
docker-compose up -d --force-recreate
```

### Edit Dashboard
```bash
nano dashboard/index.html
# Changes are immediate (mounted as volume)
```

### Edit API
```bash
nano scripts/dashboard-api.py
docker exec mediabox-controller supervisorctl restart flask-api
```

## 🎯 Next Steps

1. ✅ **Access Dashboard**: http://localhost:8080
2. ✅ **Configure Home Assistant**: http://localhost:8123
3. ✅ **Test Audio Switching**: Use dashboard buttons
4. ✅ **Add IPTV Playlist**: Copy M3U file to container
5. ✅ **Set Up Voice Control**: Follow voice API setup guide

## 📚 Documentation

- **Detailed Docker Guide**: [DOCKER_README.md](DOCKER_README.md)
- **Full Setup Instructions**: [SETUP.md](SETUP.md)
- **Implementation Details**: [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **Main README**: [README.md](README.md)

## 🆘 Get Help

```bash
# API documentation
curl http://localhost:8080/api/ | jq

# Voice setup guide
curl http://localhost:8081/voice/api/setup-guide | jq

# Service status
docker exec mediabox-controller supervisorctl status

# All logs
docker exec mediabox-controller tail -f /var/log/supervisor/*.log
```

## 🎉 You're Ready!

Everything is set up and ready to use. Enjoy your all-in-one media + smart home controller!

For advanced configuration and troubleshooting, see [DOCKER_README.md](DOCKER_README.md).

