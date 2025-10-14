# Widevine CDM Installation Guide

## Current Status

Widevine CDM is **not installed** in your Electron app, which is why Netflix and other DRM-protected services show the M7701-1003 error.

## What is Widevine CDM?

Widevine is a DRM (Digital Rights Management) system used by Netflix, YouTube, Amazon Prime Video, and other streaming services to protect content. Without it, these services cannot play protected content.

## Current Behavior

### Electron Mode:
- ✅ Preview window opens successfully
- ⚠️ Netflix shows M7701-1003 error (Widevine not available)
- ✅ Non-DRM services work (Plex, etc.)
- ℹ️ Shows message: "Opening Netflix - Widevine may not be available"

### Browser Mode:
- ✅ Netflix works perfectly (browser has Widevine)
- ✅ All services work
- ℹ️ Shows message: "Opening Browser - Widevine Support not enabled in Electron"

## How to Install Widevine CDM

### Step 1: Install/Update Chrome

1. Download and install Google Chrome (if not already installed)
2. Open Chrome and go to `chrome://components/`
3. Find "Widevine Content Decryption Module"
4. Click "Check for update"
5. Wait for update to complete

### Step 2: Locate Widevine Files

After updating, Widevine files will be in:
```
C:\Users\[YourUsername]\AppData\Local\Google\Chrome\User Data\WidevineCdm\[VERSION]\_platform_specific\win_x64\
```

You need these files:
- `widevinecdm.dll`
- `widevinecdmadapter.dll`

### Step 3: Copy Files to Electron

1. Create a `widevine` folder in your project:
   ```
   mkdir widevine
   ```

2. Copy the two DLL files to this folder:
   ```
   copy "C:\Users\[YourUsername]\AppData\Local\Google\Chrome\User Data\WidevineCdm\[VERSION]\_platform_specific\win_x64\widevinecdm.dll" widevine\
   copy "C:\Users\[YourUsername]\AppData\Local\Google\Chrome\User Data\WidevineCdm\[VERSION]\_platform_specific\win_x64\widevinecdmadapter.dll" widevine\
   ```

### Step 4: Configure Electron

Update `main.js` to use Widevine:

```javascript
const { app } = require('electron');
const path = require('path');

// Add Widevine CDM path
app.commandLine.appendSwitch('widevine-cdm-path', path.join(__dirname, 'widevine'));
app.commandLine.appendSwitch('widevine-cdm-version', 'VERSION'); // Replace with actual version

// Enable Widevine
app.commandLine.appendSwitch('enable-features', 'WidevineCdm');
```

### Step 5: Restart App

1. Stop the Electron app (Ctrl+C)
2. Restart: `npm start`
3. Test Netflix

## Alternative: Use Browser Mode

If installing Widevine is too complex, you can use browser mode:

1. **Click the PIP toggle button** in the header (top-right)
2. **Toggle it OFF** (button shows "Preview OFF")
3. **Click Netflix**
4. **Netflix opens in your default browser** with full Widevine support

## Verification

### Check if Widevine is Installed:

In the Electron app console:
```javascript
navigator.requestMediaKeySystemAccess('com.widevine.alpha', [{
  initDataTypes: ['cenc'],
  audioCapabilities: [{ contentType: 'audio/mp4;codecs="mp4a.40.2"' }],
  videoCapabilities: [{ contentType: 'video/mp4;codecs="avc1.42E01E"' }]
}]).then(keySystemAccess => {
  console.log('Widevine is available!');
}).catch(err => {
  console.log('Widevine is NOT available:', err);
});
```

## Troubleshooting

### Issue: Widevine files not found in Chrome
**Solution**: Update Chrome to the latest version

### Issue: Electron still shows M7701-1003 error
**Solution**: 
1. Verify files are in the correct location
2. Check version number matches in command line switch
3. Restart Electron app

### Issue: Files copied but still not working
**Solution**:
1. Check file paths are correct
2. Verify DLL files are for the correct architecture (win_x64)
3. Try reinstalling Electron: `npm install electron@latest`

## Current Recommendation

**Use Browser Mode for DRM services** (Netflix, YouTube, Prime Video):
- ✅ Simple - no installation needed
- ✅ Works immediately
- ✅ Full Widevine support
- ✅ No configuration required

**Use Electron Mode for non-DRM services** (Plex, etc.):
- ✅ Integrated preview
- ✅ Better user experience
- ✅ Works without Widevine

## Build Information

- **Build Number**: 17
- **Status**: Working with browser mode fallback
- **Widevine**: Not installed (optional)

---

**Note**: Installing Widevine is optional. Browser mode works perfectly for DRM-protected services.

