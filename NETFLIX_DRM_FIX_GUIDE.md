# Netflix DRM Fix Guide - Build 17

## Current Status

The preview window is creating successfully, but Netflix is still showing the M7701-1003 DRM error.

## What We've Done

### 1. **Added Comprehensive DRM Command Line Switches** (main.js)
- 21 DRM-related features enabled
- Widevine CDM enabled
- Hardware acceleration enabled
- All modern codecs enabled

### 2. **Enhanced PIP Window Settings** (main.js)
- `plugins: true` - Enable DRM plugins
- `experimentalFeatures: true` - Enable experimental features
- `enableBlinkFeatures` - Enable encrypted media
- `show: false` then `pipWindow.show()` - Load before showing

### 3. **Added Permission Handler** (main.js)
- Automatically allows media and DRM permissions
- Logs permission requests

### 4. **Enhanced Error Handling** (main.js)
- All IPC handlers have try-catch blocks
- Detailed console logging
- Null checks

## Current Console Output

### Success:
```
[Main] App ready, creating window...
[Main] Protected content enabled in session
[PiP] Opening netflix with URL: https://www.netflix.com
[PiP] Electron mode - creating positioned window
[PiP] Creating window at bounds: {width: 805, height: 617, x: 490, y: 295}
[Main] Creating PIP window: { url: 'https://www.netflix.com', ... }
[Main] Creating new BrowserWindow
[Main] PIP window created, loading URL
[Main] URL loaded, setting up event listeners
[Main] PIP window setup complete
[PiP] Preview window created successfully
```

### Issue:
Netflix still shows: "Error Code M7701-1003"

## Possible Causes

### 1. **Widevine CDM Not Installed**
Electron should come with Widevine CDM, but it might not be installed.

**Check:**
```powershell
# Check Electron version
npm list electron

# Check if Widevine is available
# Open DevTools in the PIP window and check:
# chrome://components
```

### 2. **Windows DRM Settings**
Windows might be blocking DRM content.

**Fix:**
1. Open Windows Settings
2. Go to Apps > Video Playback
3. Enable "Play protected content"
4. Restart the app

### 3. **Electron Version**
Older versions of Electron might not have Widevine CDM.

**Check:**
```powershell
npm list electron
```

**Update if needed:**
```powershell
npm install electron@latest
```

### 4. **Cache Issues**
Corrupted cache might be causing issues.

**Fix:**
```powershell
# Clear Electron cache
Remove-Item -Recurse -Force "$env:APPDATA\mediabox-v2-electron"
```

## Testing Steps

### Step 1: Check Electron Version
```powershell
npm list electron
```

Should show: `electron@28.0.0` or higher

### Step 2: Clear Cache
```powershell
Remove-Item -Recurse -Force "$env:APPDATA\mediabox-v2-electron"
```

### Step 3: Restart App
```powershell
npm start
```

### Step 4: Test Netflix
1. Click Netflix button
2. Watch console for `[Main]` and `[PiP]` messages
3. Check if Netflix loads

### Step 5: Check PIP Window DevTools
1. In the PIP window, press F12
2. Go to Console tab
3. Type: `chrome://components`
4. Look for "Widevine Content Decryption Module"
5. Check if it's installed and up to date

## Alternative Solutions

### Solution 1: Use Chrome Instead
If Electron doesn't work, you can:
1. Open Chrome browser
2. Go to `chrome://components`
3. Update Widevine CDM
4. Go to `chrome://settings/content/protectedContent`
5. Enable "Sites can play protected content"
6. Test Netflix in Chrome

### Solution 2: Use Netflix App
Instead of web version:
1. Install Netflix Windows app from Microsoft Store
2. Use that for Netflix playback

### Solution 3: Use Browser Mode
In the dashboard:
1. Enable "Browser Mode" (toggle in header)
2. Click Netflix
3. Netflix opens in your default browser
4. Browser handles DRM

## Debugging Commands

### Check Widevine in PIP Window:
1. Open PIP window (click Netflix)
2. Press F12 in PIP window
3. Go to Console
4. Type: `chrome://components`
5. Look for Widevine CDM status

### Check Permissions:
```javascript
// In PIP window console
navigator.permissions.query({name: 'mediaKeySystemAccess'}).then(result => {
  console.log('Media Key System Access:', result.state);
});
```

### Check DRM Support:
```javascript
// In PIP window console
navigator.requestMediaKeySystemAccess('com.widevine.alpha', [{
  initDataTypes: ['cenc'],
  audioCapabilities: [{
    contentType: 'audio/mp4;codecs="mp4a.40.2"'
  }],
  videoCapabilities: [{
    contentType: 'video/mp4;codecs="avc1.42E01E"'
  }]
}]).then(keySystemAccess => {
  console.log('Widevine supported:', keySystemAccess);
}).catch(err => {
  console.error('Widevine not supported:', err);
});
```

## Expected Behavior

### If Working:
- Netflix loads without error
- Content plays
- No M7701-1003 error
- Console shows: `[Main] PIP window setup complete`

### If Not Working:
- Netflix shows M7701-1003 error
- Console shows: `[PiP] Preview window created successfully`
- But content doesn't play

## Next Steps

1. **Check Electron version** - Should be 28.0.0 or higher
2. **Clear cache** - Remove `$env:APPDATA\mediabox-v2-electron`
3. **Check Windows DRM settings** - Enable protected content
4. **Restart app** - `npm start`
5. **Test Netflix** - Click Netflix button
6. **Check console** - Look for `[Main]` messages
7. **Check PIP DevTools** - Press F12 in PIP window

## If Still Not Working

Try opening Netflix in your regular browser:
1. Open Chrome
2. Go to `chrome://components`
3. Update Widevine CDM
4. Go to `chrome://settings/content/protectedContent`
5. Enable "Sites can play protected content"
6. Test Netflix in Chrome

If Netflix works in Chrome but not in Electron, the issue is with Electron's Widevine CDM installation.

## Build Information

- **Build Number**: 17
- **Status**: Testing
- **Issue**: Netflix M7701-1003 DRM error

---

**Note**: The preview window is working correctly. The issue is specifically with Netflix DRM support in Electron.

