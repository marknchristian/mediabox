# MediaBox AI - Windows Quick Start

## 🪟 Running MediaBox AI on Windows

### Prerequisites

1. **Install Docker Desktop for Windows**
   - Download: https://docs.docker.com/desktop/install/windows-install/
   - Requires Windows 10/11 Pro, Enterprise, or Education (with WSL 2)
   - OR Windows 10/11 Home (with WSL 2 backend)

2. **Enable WSL 2**
   ```powershell
   wsl --install
   ```

3. **Start Docker Desktop**
   - Open Docker Desktop from Start Menu
   - Wait for it to fully start (whale icon in system tray)

### Quick Start

1. **Open PowerShell as Administrator**

2. **Navigate to project directory**
   ```powershell
   cd C:\Users\YourUsername\@TVBOX\mediabox-dev
   ```

3. **Build the container**
   ```powershell
   .\build.ps1
   ```

4. **Start the container**
   ```powershell
   .\run.ps1
   ```

5. **Access the dashboard**
   - Automatically opens in browser
   - Or manually: http://localhost:8080

### Alternative: Using Docker Compose Directly

```powershell
# Build
docker-compose build

# Start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## 📝 Important Notes for Windows

### Audio Limitations

⚠️ **Audio passthrough does NOT work on Windows Docker**

Windows Docker containers cannot directly access host audio devices. Workarounds:

1. **Network Audio Streaming**
   - Use Snapcast or similar
   - Stream from container to Windows audio

2. **VNC/Remote Desktop**
   - Use VNC to view container display
   - Audio plays on host

3. **Deploy on Linux**
   - Use VirtualBox/Hyper-V with Linux VM
   - Or deploy to dedicated Linux hardware

### File Paths

Use Windows paths in docker-compose.yml volumes if needed:
```yaml
volumes:
  - C:\Users\YourName\mediabox-dev\dashboard:/app/dashboard
```

But relative paths work better:
```yaml
volumes:
  - ./dashboard:/app/dashboard  # Recommended
```

### Line Endings

If you get errors about line endings:
```powershell
git config --global core.autocrlf false
```

Then re-clone or re-download the project.

## 🐛 Troubleshooting

### Docker Desktop Not Starting

1. Check virtualization is enabled in BIOS
2. Ensure WSL 2 is installed: `wsl --install`
3. Update Windows to latest version

### Port Already in Use

```powershell
# Check what's using port 8080
netstat -ano | findstr :8080

# Kill process (replace PID with actual number)
taskkill /PID <PID> /F
```

### Container Won't Start

```powershell
# View detailed logs
docker-compose logs

# Check Docker status
docker info

# Restart Docker Desktop
# Right-click Docker icon → Restart
```

### Cannot Access http://localhost:8080

1. Check container is running:
   ```powershell
   docker ps
   ```

2. Check port mapping:
   ```powershell
   docker port mediabox-controller
   ```

3. Try http://127.0.0.1:8080

4. Check Windows Firewall settings

### Shared Drive Access Denied

Docker Desktop Settings → Resources → File Sharing
- Add your project directory
- Apply & Restart

## 🎯 Best Practices for Windows

### Development

For developing on Windows, consider:

1. **Use WSL 2 directly**
   ```bash
   # In WSL 2 terminal
   cd /mnt/c/Users/YourName/@TVBOX/mediabox-dev
   ./build.sh
   ./run.sh
   ```

2. **VS Code + Remote Containers**
   - Install "Remote - Containers" extension
   - Open folder in container
   - Edit files with full IntelliSense

3. **Edit files on Windows**
   - Changes sync automatically via volume mounts
   - Restart services: `docker-compose restart`

### Production

For production deployment:

1. **Deploy to Linux Server**
   - Raspberry Pi 4/5
   - Intel NUC
   - Old laptop with Ubuntu

2. **Use WSL 2 for testing**
   - Full Linux environment
   - Better audio support (with PulseAudio)

3. **Or use Dedicated VM**
   - Hyper-V VM with Ubuntu
   - VirtualBox with Ubuntu Server
   - Pass through USB audio devices

## 🔧 Windows-Specific Configuration

### docker-compose.yml Modifications

For Windows, you might want to remove some Linux-specific mounts:

```yaml
# Comment out these lines in docker-compose.yml:
# - /dev/snd:/dev/snd
# - /run/user/1000/pulse:/run/pulse
# - /tmp/.X11-unix:/tmp/.X11-unix:rw
```

### Network Mode

Windows doesn't support `network_mode: host`. Use port mapping instead:

```yaml
# Already configured in docker-compose.yml
ports:
  - "8080:8080"
  - "8123:8123"
```

## 📚 Additional Resources

- [Docker Desktop for Windows Docs](https://docs.docker.com/desktop/windows/)
- [WSL 2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Docker Compose on Windows](https://docs.docker.com/compose/install/)

## 🆘 Getting Help

If you encounter issues:

1. Check logs: `docker-compose logs`
2. Verify Docker is running: `docker ps`
3. Check system resources in Docker Desktop
4. Review error messages carefully
5. Try restarting Docker Desktop

## ✅ Next Steps

Once container is running:

1. Access dashboard: http://localhost:8080
2. Configure Home Assistant: http://localhost:8123
3. Test API endpoints
4. Customize dashboard UI
5. Add your streaming service bookmarks

**Note**: For full audio functionality, consider deploying to a Linux system or using a Linux VM.

---

**Happy Streaming! 🎬📺🎵**

