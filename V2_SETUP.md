# MediaBox AI V2 - Setup & Configuration Guide

## Overview
V2 is the Electron-based desktop application, separate from V1 (web-based Docker version).

## Port Configuration

### V1 Ports (Docker - Stable)
- **8080**: Flask Dashboard API
- **8123**: Home Assistant
- **5900**: VNC
- **6080**: noVNC

### V2 Ports (Electron - Development)
- **8081**: Flask Dashboard API
- **8082**: Voice Control API
- **8124**: Home Assistant (if needed, currently not used)

**No port conflicts!** V1 and V2 can run simultaneously.

## Quick Start

### 1. Install Dependencies
```powershell
npm install
```

### 2. Start V2
```powershell
.\start-v2.ps1
```

Or manually:
```powershell
# Load environment variables
Get-Content v2-config.env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# Start backend
Start-Process python -ArgumentList "scripts/dashboard-api.py" -WindowStyle Hidden

# Start Electron
npm run dev
```

## Development

### Run in Development Mode
```powershell
npm run dev
```

### Build for Windows
```powershell
npm run build:win
```

### Build for Linux
```powershell
npm run build:linux
```

## Configuration

### Change Ports
Edit `v2-config.env`:
```env
PORT=8081              # Dashboard API
VOICE_PORT=8082        # Voice Control
```

### Environment Variables
All configuration is in `v2-config.env`:
- `PORT`: Dashboard API port (default: 8081)
- `VOICE_PORT`: Voice Control API port (default: 8082)
- `FLASK_ENV`: Flask environment (development/production)
- `FLASK_DEBUG`: Enable debug mode (1/0)
- `HASS_*`: Home Assistant configuration

## Backend Services

### Dashboard API (Port 8081)
- REST API for all controls
- Serves HTML dashboard
- Audio switching, volume control
- System management

### Voice Control API (Port 8082)
- Voice assistant interface
- Intent recognition
- Command processing

## Access URLs

When V2 is running:
- **Electron App**: Desktop window (auto-opens)
- **Dashboard API**: http://localhost:8081
- **API Docs**: http://localhost:8081/api/
- **Voice Control**: http://localhost:8082/voice/api/

## Troubleshooting

### Port Already in Use
```powershell
# Check what's using the port
netstat -ano | findstr :8081

# Kill the process
taskkill /PID <PID> /F
```

### Python Not Found
```powershell
# Install Python 3.11+
winget install Python.Python.3.11
```

### Electron Won't Start
```powershell
# Clear cache and reinstall
Remove-Item -Recurse -Force node_modules
npm install
```

### Backend Services Not Starting
```powershell
# Check if Python dependencies are installed
pip install -r requirements.txt

# Run backend manually to see errors
python scripts/dashboard-api.py
```

## V1 vs V2 Comparison

| Feature | V1 (Docker) | V2 (Electron) |
|---------|-------------|---------------|
| Platform | Web browser | Native desktop |
| Backend | Docker container | Native Python |
| Ports | 8080, 8123, etc. | 8081, 8082, etc. |
| Updates | Manual | Auto-update (planned) |
| Fullscreen | Browser F11 | True kiosk mode |
| Audio Control | Flask API | Native IPC |
| Status | Stable | Development |

## Running Both V1 and V2

You can run both simultaneously:

```powershell
# Terminal 1: Start V1 (Docker)
docker-compose up

# Terminal 2: Start V2 (Electron)
.\start-v2.ps1
```

Access:
- V1 Dashboard: http://localhost:8080
- V2 Dashboard: http://localhost:8081

## Next Steps

1. ✅ V2 configured with separate ports
2. ✅ Backend services configured
3. ✅ Startup script created
4. 🔄 Migrate dashboard UI from V1
5. ⏳ Implement native audio controls
6. ⏳ Add auto-update system
7. ⏳ Package for distribution

## Support

For issues:
1. Check logs in PowerShell
2. Verify ports are available
3. Check Python dependencies
4. Review this documentation

