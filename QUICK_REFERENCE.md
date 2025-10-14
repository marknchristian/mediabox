# MediaBox AI V2 - Quick Reference Card

## 🚀 Quick Start

### Start the App
```powershell
.\start-v2.ps1
```

### Access URLs
- **Electron App**: Auto-opens in window
- **Dashboard API**: http://localhost:8081
- **Voice Control**: http://localhost:8082

---

## 📱 Responsive Breakpoints

| Device | Width | Columns | Font Size |
|--------|-------|---------|-----------|
| Mobile | 360px - 767px | 1 | 14px - 24px |
| Tablet | 768px - 1279px | 2 | 16px - 32px |
| Standard TV | 1280px - 1919px | 3 | 18px - 48px |
| Full HD | 1920px - 3839px | 4 | 24px - 72px |
| 4K UHD | 3840px - 7679px | 5 | 36px - 96px |
| 8K UHD | 7680px+ | 6 | 72px - 192px |

---

## 🎮 Navigation Controls

### Keyboard / TV Remote
- **Tab**: Move between elements
- **Arrow Keys**: Navigate up/down/left/right
- **Enter/Space**: Activate button
- **Escape**: Go back / Close modal

### Touch Gestures
- **Swipe Left/Right**: Navigate horizontally
- **Swipe Up/Down**: Navigate vertically
- **Tap**: Activate button

---

## 🎨 Customization

### Change Colors
Edit `dashboard/responsive.css`:
```css
:root {
  --accent-color: #00D9FF;    /* Your brand color */
  --bg-primary: rgba(0, 0, 0, 0.8);
  --text-primary: #FFFFFF;
}
```

### Change Grid Columns
```css
@media (min-width: 1920px) {
  .service-grid {
    grid-template-columns: repeat(5, 1fr); /* 5 columns */
  }
}
```

---

## 🧪 Testing

### Browser DevTools
```
F12 → Device Toolbar (Ctrl+Shift+M)
Select: iPhone SE, iPad, Desktop HD, 4K
```

### Test Navigation
```
Tab: Move focus
Arrows: Navigate
Enter: Activate
```

### Test Touch
```
Swipe left/right/up/down
Tap to activate
```

---

## 📁 Key Files

| File | Purpose |
|------|---------|
| `dashboard/index.html` | Main HTML |
| `dashboard/responsive.css` | Responsive styles |
| `dashboard/responsive.js` | TV navigation |
| `start-v2.ps1` | Startup script |
| `v2-config.env` | Environment config |

---

## 🔧 Common Tasks

### Update Build Number
```powershell
# Edit dashboard/build.txt
# Edit scripts/dashboard-api.py
# Edit dashboard/index.html
```

### Change Ports
```powershell
# Edit v2-config.env
PORT=8081
VOICE_PORT=8082
```

### Rebuild
```powershell
# Stop app (Ctrl+C)
# Restart
.\start-v2.ps1
```

---

## 🐛 Troubleshooting

### Styles Not Loading
```powershell
# Clear cache
Ctrl+F5 (Windows)
Cmd+Shift+R (Mac)
```

### Navigation Not Working
```powershell
# Check console (F12)
# Make sure responsive.js loaded
# Try Tab first to focus element
```

### Port Already in Use
```powershell
# Find process
netstat -ano | findstr :8081

# Kill process
taskkill /PID <PID> /F
```

---

## 📚 Documentation

- **UI_SUMMARY.md** - Overview
- **IMPLEMENTATION_STEPS.md** - Quick start
- **UI_IMPROVEMENTS_GUIDE.md** - Complete guide
- **INTEGRATION_COMPLETE.md** - Integration details
- **QUICK_REFERENCE.md** - This file

---

## 🎯 Port Configuration

### V1 (Docker - Stable)
- 8080: Dashboard API
- 8123: Home Assistant
- 5900: VNC
- 6080: noVNC

### V2 (Electron - Development)
- 8081: Dashboard API ✅
- 8082: Voice Control ✅

**No conflicts!** Both can run simultaneously.

---

## ⚡ Performance Tips

1. **Lazy Load Images**: Automatic
2. **Debounced Events**: Automatic
3. **Smooth Animations**: 60fps
4. **Fast Load**: < 3 seconds

---

## 🎉 Features

✅ Responsive (mobile to 8K)  
✅ TV remote navigation  
✅ Touch gestures  
✅ Fluid typography  
✅ Performance optimized  
✅ Accessibility support  

---

**Need Help?** Check the documentation files or run `.\start-v2.ps1` to test!

