# 🎬 MediaBox AI - Complete All-in-One Media & Smart Home Controller

> **Status**: ✅ Production Ready | **Version**: 1.0.0 | **License**: MIT

A fully containerized media center + smart home controller running in a single Docker container. Control Netflix, Plex, YouTube, IPTV, manage audio outputs, and integrate with Home Assistant - all from a beautiful web dashboard.

---

## 🎯 What Is This?

MediaBox AI is a **complete home entertainment system** that runs in Docker and provides:

✅ **Beautiful Web Dashboard** - Modern UI with streaming service launchers  
✅ **REST API** - Control everything programmatically  
✅ **Audio Management** - Switch between HDMI, SPDIF, and Analog outputs  
✅ **Home Assistant** - Smart home integration built-in  
✅ **IPTV Support** - Live TV via VLC or Hypnotix  
✅ **Voice Control Ready** - Framework + setup guide included  
✅ **One Container** - Everything runs together with auto-restart  

---

## 🚀 Quick Start

### For Linux/Mac:

```bash
chmod +x build.sh run.sh
./build.sh
./run.sh
```

### For Windows (PowerShell):

```powershell
.\build.ps1
.\run.ps1
```

### Access Services:

- **Dashboard**: http://localhost:8080
- **Home Assistant**: http://localhost:8123
- **API Docs**: http://localhost:8080/api/

---

## 📦 What's Included

### 🎨 Web Dashboard
- Modern glassmorphism design
- One-click service launchers (Netflix, Plex, Amazon, YouTube)
- Real-time audio device switching
- Volume control with live feedback
- System power controls
- Status indicators

### 🔌 REST API
Complete control via HTTP endpoints:
- Launch streaming services
- Switch audio outputs
- Control volume
- System management (shutdown/restart)
- Health checks and status

### 🔊 Audio Management
- Auto-detect all PulseAudio devices
- Switch between HDMI, SPDIF (Optical/Coax), Analog
- Bit-perfect passthrough support
- Volume control
- CLI and API interfaces

### 🏠 Home Assistant
- Runs in same container
- Smart home device control
- Automation platform
- Persistent configuration
- Accessible at :8123

### 📺 IPTV Support
- VLC integration
- Hypnotix support
- M3U playlist handling
- Direct stream URLs
- Auto-detection of players

### 🎤 Voice Control (Framework)
- API structure ready
- Setup guide included
- voice2json integration docs
- GPT intent recognition
- Test endpoints

---

## 📁 Project Structure

```
mediabox-dev/
├── Dockerfile                   # Container definition
├── docker-compose.yml           # Service orchestration
├── supervisord.conf             # Process manager
├── requirements.txt             # Python dependencies
│
├── dashboard/
│   └── index.html              # Web dashboard
│
├── scripts/
│   ├── dashboard-api.py        # Main Flask API
│   ├── audio-switcher.py       # Audio management
│   ├── iptv-launcher.py        # IPTV launcher
│   ├── voice-control-api.py    # Voice control API
│   └── start-dashboard.sh      # Startup script
│
├── ha_config/                  # Home Assistant data
│
└── Documentation/
    ├── QUICKSTART.md           # Quick reference
    ├── DOCKER_README.md        # Docker guide
    ├── SETUP.md                # Setup instructions
    ├── WINDOWS_README.md       # Windows-specific guide
    └── PROJECT_SUMMARY.md      # Technical summary
```

---

## 🎮 Usage

### Web Dashboard

1. Open http://localhost:8080
2. Click service buttons to launch apps
3. Use audio controls to switch outputs
4. Adjust volume with slider
5. Monitor status messages

### API Examples

```bash
# Launch Netflix
curl -X POST http://localhost:8080/api/launch/netflix

# Switch to HDMI audio
curl -X POST http://localhost:8080/api/switch-audio \
  -H "Content-Type: application/json" \
  -d '{"output":"hdmi"}'

# Set volume to 75%
curl -X POST http://localhost:8080/api/volume \
  -H "Content-Type: application/json" \
  -d '{"volume":75}'

# Get system status
curl http://localhost:8080/api/status
```

### CLI Tools

```bash
# Enter container
docker exec -it mediabox-controller bash

# List audio devices
python3 /app/scripts/audio-switcher.py list

# Switch audio output
python3 /app/scripts/audio-switcher.py switch --name hdmi

# Launch IPTV
python3 /app/scripts/iptv-launcher.py --vlc
```

---

## 🔧 Configuration

### Environment Variables

Edit `docker-compose.yml`:

```yaml
environment:
  - TZ=America/New_York        # Your timezone
  - PORT=8080                  # Flask port
  - DISPLAY=:0                 # X11 display
```

### Service URLs

Edit `scripts/dashboard-api.py`:

```python
SERVICE_URLS = {
    'netflix': 'https://www.netflix.com',
    'plex': 'http://localhost:32400/web',
    # Add your own...
}
```

### Dashboard Customization

Edit `dashboard/index.html` - changes are immediate (mounted as volume).

---

## 🐳 Docker Commands

```bash
# Build container
./build.sh

# Start services
./run.sh

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Stop
docker-compose down

# Shell access
docker exec -it mediabox-controller bash

# Check service status
docker exec mediabox-controller supervisorctl status
```

---

## 🎯 Platform Support

### ✅ Linux (Recommended)
- Full audio support
- PulseAudio integration
- All features work
- Best performance

### ⚠️ Windows (Limited)
- Dashboard works perfectly
- API fully functional
- Home Assistant works
- ❌ Audio passthrough not supported (Docker limitation)
- See [WINDOWS_README.md](WINDOWS_README.md) for details

### ⚠️ macOS (Limited)
- Dashboard works
- API works
- ❌ Audio requires workarounds
- Consider Linux VM for full functionality

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | Quick reference guide |
| [DOCKER_README.md](DOCKER_README.md) | Complete Docker guide |
| [SETUP.md](SETUP.md) | Installation & setup |
| [WINDOWS_README.md](WINDOWS_README.md) | Windows-specific guide |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Technical details |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Implementation notes |

---

## 🔍 Troubleshooting

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
```

See [DOCKER_README.md](DOCKER_README.md) for comprehensive troubleshooting.

---

## 🛠️ Technology Stack

- **Container**: Docker + Docker Compose
- **Process Manager**: Supervisor
- **API**: Flask 3.0 + Python 3.11
- **Audio**: PulseAudio
- **Smart Home**: Home Assistant 2024.1
- **Video**: VLC, Chromium
- **Frontend**: HTML5 + CSS3 + JavaScript
- **Display**: Xvfb (headless X11)

---

## 🎓 Use Cases

### Home Theater PC
- Connect to TV via HDMI
- Use as streaming device
- Remote control via phone (KDE Connect)
- Switch between streaming services

### Smart Home Hub
- Central control point
- Home Assistant integration
- Voice control (with setup)
- Automation platform

### Media Server
- Plex server + client
- IPTV streaming
- Audio management
- Multi-room audio

### Development Platform
- REST API for custom integrations
- Python automation scripts
- Home automation testing
- Media system development

---

## 🚦 Service Status

| Service | Port | Status | Auto-Start |
|---------|------|--------|------------|
| Flask Dashboard | 8080 | ✅ Ready | Yes |
| Home Assistant | 8123 | ✅ Ready | Yes |
| Voice Control API | 8081 | ⚠️ Placeholder | Optional |
| PulseAudio | - | ✅ Ready | Yes |
| Xvfb (Display) | - | ✅ Ready | Yes |

---

## 🔐 Security Notes

- Container runs as non-root user `mediabox`
- No exposed credentials in code
- Use environment variables for secrets
- Firewall rules recommended for production
- HTTPS recommended for remote access

---

## 🎉 Next Steps

1. ✅ **Build & Deploy**: Run `./build.sh` and `./run.sh`
2. ✅ **Access Dashboard**: http://localhost:8080
3. ✅ **Configure Home Assistant**: http://localhost:8123
4. ✅ **Test Audio Switching**: Use dashboard controls
5. ⬜ **Add IPTV Playlist**: Copy M3U file
6. ⬜ **Set Up Voice Control**: Follow setup guide
7. ⬜ **Customize**: Edit dashboard and services

---

## 🤝 Contributing

This is a personal project, but feel free to:
- Fork and modify for your needs
- Submit issues if you find bugs
- Share improvements
- Adapt to your setup

---

## 📄 License

MIT License - Free to use and modify

---

## 🙏 Acknowledgments

Built with:
- Flask (Pallets Projects)
- Home Assistant (Nabu Casa)
- PulseAudio (freedesktop.org)
- Docker (Docker Inc.)
- VLC (VideoLAN)

---

## 📞 Support & Help

### For Setup Issues
- See [QUICKSTART.md](QUICKSTART.md)
- Check [DOCKER_README.md](DOCKER_README.md)
- Review logs: `docker-compose logs`

### For Windows Users
- See [WINDOWS_README.md](WINDOWS_README.md)
- Consider WSL 2 or Linux VM

### For Development
- See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
- Review API docs: http://localhost:8080/api/

---

## 🎬 Screenshots & Demo

### Dashboard
Beautiful glassmorphism design with intuitive controls.

### Features
- One-click service launching
- Real-time audio switching
- Volume control
- System management

---

## ⭐ Key Features

🎨 **Beautiful UI** - Modern, responsive dashboard  
🔌 **Complete API** - REST endpoints for everything  
🔊 **Audio Control** - Multi-output management  
🏠 **Smart Home** - Home Assistant integration  
📺 **IPTV Ready** - Live TV support  
🎤 **Voice Ready** - Framework included  
🐳 **One Container** - Simple deployment  
🔄 **Auto-Restart** - Supervisor managed  
📝 **Full Docs** - Comprehensive guides  

---

**Ready to transform your home entertainment? Let's get started! 🚀**

```bash
./build.sh && ./run.sh
```

**Then open: http://localhost:8080**

---

*Built with ❤️ for the ultimate home entertainment experience*

