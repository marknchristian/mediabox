# MediaBox AI

A modular, Docker-based Linux media center with support for streaming, Plex, remote control, and digital audio passthrough.

## Features

- 🎨 Modern HTML5 Dashboard with glassmorphism design
- 📺 One-click access to Netflix, Amazon Prime, Plex, YouTube
- 🔊 Real-time audio output switching (SPDIF, HDMI, Analog)
- 🎚️ Volume control with live feedback
- 📡 IPTV support via Hypnotix
- 🏠 Smart Home integration (Home Assistant)
- 🔌 System controls (shutdown, restart)
- 🌐 REST API for programmatic control
- 📱 Remote control via KDE Connect and VNC

See `.cursor/prompt.txt` for full Cursor setup.


---

## 🧠 Smart Home & Voice Assistant Integration

### Live TV Support:
- Use `iptv-launcher.py` to launch Hypnotix (IPTV client)
- Add your M3U/EPG to Hypnotix manually or via config
- Dashboard button `📡 Live TV` opens it from your IR remote or UI

### Smart Home (via Home Assistant):
- Add Home Assistant container with Docker Compose
- Access UI at: http://localhost:8123
- Control your Xiaomi / Google-integrated devices via LAN

### Voice Assistant (LLM-ready):
- Option A: Use `voice2json` + GPT for offline STT + online NLU
- Option B: Install `Leon` for plugin-based voice control
- Option C: Optional support for Mycroft as a fallback

---

## 🚀 Quick Start

### Installation

1. Install Python dependencies:
```bash
pip3 install -r requirements.txt
```

2. Make scripts executable:
```bash
chmod +x scripts/*.py scripts/*.sh
```

3. Start the dashboard:
```bash
./scripts/start-dashboard.sh
```

Or manually:
```bash
# Start API server
python3 scripts/dashboard-api.py

# Launch dashboard in browser
chromium-browser --app=file://$(pwd)/dashboard/index.html
```

### Using Docker

```bash
docker-compose up -d
docker exec -it mediabox-dev bash
cd /home/mediabox
./scripts/start-dashboard.sh
```

---

## 📡 API Endpoints

The Flask API server runs on `http://localhost:5000/api/`

### Launch Services
- `POST /api/launch/<service>` - Launch streaming service
  - Services: netflix, amazon, youtube, plex, livetv, smarthome

### Audio Control
- `GET /api/audio-devices` - List available audio devices
- `POST /api/switch-audio` - Switch audio output
  - Body: `{"output": "hdmi|spdif|analog"}`
- `GET /api/volume` - Get current volume
- `POST /api/volume` - Set volume
  - Body: `{"volume": 0-100}`

### System Control
- `POST /api/shutdown` - Shutdown system
- `POST /api/restart` - Restart system
- `GET /api/status` - Get system status
- `GET /api/health` - Health check

---

## 🎛️ Command-Line Tools

### Audio Switcher

```bash
# Interactive mode
./scripts/audio-switcher.py

# List audio devices
./scripts/audio-switcher.py list

# Switch by index
./scripts/audio-switcher.py switch --index 0

# Switch by name pattern
./scripts/audio-switcher.py switch --name hdmi

# Set volume
./scripts/audio-switcher.py volume --set 75

# Get volume
./scripts/audio-switcher.py volume --get

# JSON output
./scripts/audio-switcher.py list --json
```

---

## 🔧 Configuration

### PulseAudio Setup

Ensure PulseAudio is running and accessible:
```bash
pulseaudio --check
pactl list sinks short
```

### Chromium Kiosk Mode

The dashboard launches in kiosk mode for a TV-friendly full-screen experience.

---

## 🐳 Docker Setup

The `docker-compose.yml` is configured for:
- Host network mode (access to PulseAudio and X11)
- Shared X11 socket for GUI apps
- PulseAudio socket binding
- Access to `/dev/snd` for audio devices
- Access to `/dev/input` and `/dev/lirc0` for IR remote control

---

## 🎯 Future Enhancements

### Voice Assistant Integration:
- Option A: Use `voice2json` + GPT for offline STT + online NLU
- Option B: Install `Leon` for plugin-based voice control
- Option C: Optional support for Mycroft as a fallback
- Build a Flask or WebSocket GPT interface that interprets STT and issues actions to Home Assistant via its REST API

### ISO Conversion:
- Package as bootable ISO using Ubuntu customization tools
- Auto-start dashboard on boot
- Minimal system with only required packages
