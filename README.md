# MediaBox AI V2 - Electron Desktop Dashboard

## Overview
This is the Electron-based desktop version of MediaBox AI, forked from V1 (web-based dashboard).

## What's New in V2
- **Native Desktop App**: Built with Electron for Windows/Linux
- **Fullscreen Kiosk Mode**: Optimized for TV/display usage
- **Native System Controls**: Direct access to audio, power, and system functions
- **No Browser Required**: Self-contained application
- **Better Performance**: Native rendering and hardware acceleration

## Development Status
🚧 **IN PROGRESS** - Refactoring from V1 web dashboard

### Current State
- ✅ Project structure created
- ✅ Electron main process configured
- ✅ IPC bridge for system controls
- 🔄 Dashboard UI migration (in progress)
- ⏳ Native audio device control (planned)
- ⏳ Native power management (planned)
- ⏳ Auto-update system (planned)

## Installation

### Prerequisites
- Node.js 18+ and npm
- Git

### Setup
```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build for Windows
npm run build:win

# Build for Linux
npm run build:linux
```

## Project Structure
```
mediabox-v2-electron/
├── main.js              # Electron main process
├── preload.js           # IPC bridge for security
├── package.json         # Project config
├── dashboard/           # UI (migrated from V1)
│   ├── index.html
│   └── ...
├── scripts/             # Backend services (to be refactored)
└── build/               # Build assets (icons, etc.)
```

## Differences from V1
| Feature | V1 (Web) | V2 (Electron) |
|---------|----------|---------------|
| Platform | Browser-based | Native desktop app |
| Audio Control | Flask API proxy | Native Node.js |
| System Control | Flask API proxy | Native IPC |
| Updates | Manual | Auto-update |
| Performance | Browser limits | Native rendering |
| Fullscreen | Browser F11 | True kiosk mode |

## Development Roadmap
1. ✅ Fork and initialize Electron project
2. 🔄 Migrate dashboard UI (in progress)
3. ⏳ Refactor system controls to use Electron IPC
4. ⏳ Implement native audio device management
5. ⏳ Add auto-update mechanism
6. ⏳ Optimize for TV/remote control navigation
7. ⏳ Add hardware acceleration
8. ⏳ Package for distribution

## V1 vs V2 Comparison

### V1 (mediabox-v1)
- Web-based dashboard
- Flask backend API
- Browser-accessible
- Good for development/testing

### V2 (mediabox-v2-electron)
- Native desktop application
- Electron + Node.js
- Kiosk mode for TVs
- Production-ready distribution

## Contributing
This is an active development project. See `docs/` for detailed architecture and contribution guidelines.

## License
MIT

## Links
- V1 Repository: `../mediabox-v1/`
- V2 Repository: `./` (this directory)
- Main Dashboard: https://netlite.network/mediabox

## Installable App Icons (Electron + PWA)

- Electron installers use icons from `build/`:
  - Windows: `build/icon.ico`
  - Linux: `build/icon.png`
- Web/PWA install prompts on Android/desktop browsers use `dashboard/manifest.json` and icons in `dashboard/icons/`.
- Minimal service worker `dashboard/sw.js` is registered to enable the install button in supported browsers.
