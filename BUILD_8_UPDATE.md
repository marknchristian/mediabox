# Build 8 Update - MediaBox AI V2

## Update Summary
**Date**: January 15, 2025  
**Build Number**: 8  
**Version**: 2.0.0  

## Changes in Build 8

### ✅ V2 Electron Setup Complete
- Node.js v22.20.0 LTS installed
- All npm dependencies installed
- V2 configured with separate ports (no conflicts with V1)

### 🔧 Port Configuration
**V1 Ports (Docker - Stable):**
- 8080: Dashboard API
- 8123: Home Assistant
- 5900: VNC
- 6080: noVNC

**V2 Ports (Electron - Development):**
- **8081**: Dashboard API ✅
- **8082**: Voice Control API ✅

### 📦 New Files Created
1. **`v2-config.env`** - V2 environment configuration
2. **`start-v2.ps1`** - Windows startup script for V2
3. **`V2_SETUP.md`** - Complete V2 setup documentation
4. **`BUILD_8_UPDATE.md`** - This file

### 🔄 Files Updated
1. **`dashboard/build.txt`** - Updated from "7" to "8"
2. **`scripts/dashboard-api.py`** - Updated BUILD_NUMBER to "2025.01.15.008"
3. **`dashboard/index.html`** - Updated build display from "Build 7" to "Build 8"

### 🚀 How to Run V2

**Quick Start:**
```powershell
.\start-v2.ps1
```

**Manual Start:**
```powershell
# Load environment
Get-Content v2-config.env | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
    }
}

# Start Electron
npm run dev
```

### 🌐 Access URLs
- **Electron App**: Desktop window (auto-opens)
- **Dashboard API**: http://localhost:8081
- **Voice Control**: http://localhost:8082

### 🔄 Running Both V1 and V2

You can now run both versions simultaneously:

```powershell
# Terminal 1: Start V1 (Docker)
docker-compose up

# Terminal 2: Start V2 (Electron)
.\start-v2.ps1
```

### 📊 Version History

| Build | Date | Description |
|-------|------|-------------|
| 8 | 2025-01-15 | V2 Electron setup complete, separate ports configured |
| 7 | 2024-10-11 | Previous stable build |
| 6 | 2024-10-10 | IPTV support added |
| 5 | 2024-10-09 | Voice control API |
| 4 | 2024-10-08 | Audio switching |
| 3 | 2024-10-07 | Dashboard UI |
| 2 | 2024-10-06 | Flask API |
| 1 | 2024-10-05 | Initial release |

### 🎯 Next Steps

1. ✅ V2 configured with separate ports
2. ✅ Backend services configured
3. ✅ Startup script created
4. 🔄 Migrate dashboard UI from V1
5. ⏳ Implement native audio controls
6. ⏳ Add auto-update system
7. ⏳ Package for distribution

### 📚 Documentation
- **V2 Setup**: See `V2_SETUP.md`
- **V1 Docker**: See `DOCKER_README.md`
- **Project Summary**: See `PROJECT_SUMMARY.md`
- **Quick Start**: See `QUICKSTART.md`

### 🔍 Build Files Reference

All build numbers are now synchronized across:
- `dashboard/build.txt` → "8"
- `scripts/dashboard-api.py` → BUILD_NUMBER = "2025.01.15.008"
- `dashboard/index.html` → "Build 8" (display and fallback)

### ⚠️ Important Notes

1. **V1 is stable and won't be updated** - All future development is on V2
2. **No port conflicts** - V1 and V2 can run simultaneously
3. **V2 requires Node.js** - Installed via winget (Node.js v22.20.0 LTS)
4. **Python required** - For backend services (Python 3.13 detected)

### 🐛 Known Issues
None at this time.

### 📝 Build 8 Changelog

**Added:**
- Node.js v22.20.0 LTS installation
- npm v10.9.3
- Electron v28.0.0
- V2 port configuration (8081, 8082)
- V2 startup script
- V2 setup documentation

**Updated:**
- Build number from 7 to 8
- BUILD_NUMBER timestamp to 2025.01.15.008
- Dashboard build display

**Fixed:**
- Port conflicts between V1 and V2
- Environment variable configuration

---

**Build 8 Complete** ✅  
*MediaBox AI V2 is now ready for development*

