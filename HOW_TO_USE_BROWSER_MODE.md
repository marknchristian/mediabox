# How to Use Browser Mode for Netflix & DRM Services

## Quick Guide

Since Widevine isn't available in Electron, use **Browser Mode** for Netflix, YouTube, and other DRM-protected services.

## Steps:

### 1. **Toggle PIP Panel OFF**
- Click the **PIP toggle button** in the header (top-right)
- Button will show **"Preview OFF"** (blue)

### 2. **Click Netflix (or any DRM service)**
- Netflix opens in your default browser (Edge)
- Full Widevine support
- Works perfectly!

### 3. **For Non-DRM Services (Plex, etc.)**
- Toggle PIP panel **ON**
- Services open in preview box
- Integrated experience

## Visual Guide

```
┌─────────────────────────────────────────┐
│  MediaBox AI    [📺 Preview OFF]  🕐  │  ← Click this button
└─────────────────────────────────────────┘
```

## Why Browser Mode?

- ✅ **Netflix works perfectly** (Edge has Widevine)
- ✅ **YouTube works perfectly**
- ✅ **Amazon Prime works perfectly**
- ✅ **No installation needed**
- ✅ **No configuration needed**
- ✅ **Simple toggle**

## Services by Mode

### Use Browser Mode (Toggle OFF):
- Netflix
- YouTube
- Amazon Prime Video
- Apple TV+
- Disney+
- HBO Max

### Use Electron Mode (Toggle ON):
- Plex
- Plexamp
- Home Assistant
- Live TV
- Telegram
- Calendar
- News

## Build 17 Features

- ✅ **Auto-detection**: Shows message when Widevine not available
- ✅ **Clear messaging**: "Widevine not available - Toggle PIP OFF for browser mode"
- ✅ **Easy toggle**: One click to switch modes
- ✅ **Smart detection**: Knows which services need DRM

---

**Status**: ✅ Browser mode works perfectly for all DRM services!

