# Debug Preview Issue - "Failed to Open"

## Issue
Getting "failed to open" error when trying to preview services in Electron mode.

## Debugging Steps

### 1. Check Console Logs
Open DevTools (F12) and look for these logs:
- `[PiP] Opening [service] with URL: [url]`
- `[PiP] isElectron: true/false`
- `[PiP] Electron mode - embedding in iframe`
- `[PiP] Viewport found, creating iframe`
- `[PiP] Setting iframe src to: [url]`
- `[PiP] Iframe loaded successfully` OR `[PiP] Iframe failed to load`

### 2. Check Electron Mode
Verify you're running in Electron mode:
```javascript
// In console, type:
console.log('isElectron:', typeof window !== 'undefined' && window.electronAPI !== undefined);
console.log('electronAPI:', window.electronAPI);
```

Should output:
- `isElectron: true`
- `electronAPI: [object]`

### 3. Check Viewport Element
Verify the viewport exists:
```javascript
// In console, type:
console.log('Viewport:', document.getElementById('pipViewport'));
```

Should output: `Viewport: <div class="pip-viewport" id="pipViewport">...</div>`

### 4. Check Iframe Creation
After clicking a service, check if iframe was created:
```javascript
// In console, type:
console.log('Iframe:', document.getElementById('pip-embedded-frame'));
```

Should output: `Iframe: <iframe id="pip-embedded-frame">...</iframe>`

### 5. Check Iframe Source
Verify the iframe has the correct URL:
```javascript
// In console, type:
const iframe = document.getElementById('pip-embedded-frame');
console.log('Iframe src:', iframe ? iframe.src : 'Not found');
```

### 6. Common Issues

#### Issue 1: Not in Electron Mode
**Symptom**: `isElectron: false`
**Solution**: Make sure you're running the Electron app, not opening in browser

#### Issue 2: electronAPI Not Available
**Symptom**: `electronAPI: undefined`
**Solution**: Check `preload.js` is loading correctly

#### Issue 3: Viewport Not Found
**Symptom**: `Viewport: null`
**Solution**: Check HTML structure, viewport should exist

#### Issue 4: Iframe Not Creating
**Symptom**: `Iframe: null`
**Solution**: Check console for errors when creating iframe

#### Issue 5: CORS/Security Error
**Symptom**: Console shows CORS or security error
**Solution**: Check iframe sandbox attributes

#### Issue 6: URL Not Loading
**Symptom**: Iframe src is set but page doesn't load
**Solution**: Check if URL is accessible, try opening in browser

### 7. Test URLs

Try these test URLs to verify iframe works:
```javascript
// Simple test
iframe.src = 'https://www.google.com';

// Netflix test
iframe.src = 'https://www.netflix.com';

// YouTube test
iframe.src = 'https://www.youtube.com';
```

### 8. Manual Test

Open console and run:
```javascript
// Create test iframe
const testIframe = document.createElement('iframe');
testIframe.src = 'https://www.google.com';
testIframe.style.width = '100%';
testIframe.style.height = '400px';
testIframe.style.border = '2px solid red';
document.body.appendChild(testIframe);

// Check if it loads
testIframe.onload = () => console.log('Test iframe loaded!');
testIframe.onerror = () => console.error('Test iframe failed!');
```

### 9. Check Network Tab

1. Open DevTools
2. Go to Network tab
3. Click a service button
4. Look for:
   - Request to the service URL
   - Response status (200, 404, etc.)
   - Any blocked requests

### 10. Check Security Settings

Verify Electron security settings in `main.js`:
```javascript
webPreferences: {
  nodeIntegration: false,
  contextIsolation: true,
  preload: path.join(__dirname, 'preload.js'),
  plugins: true,        // Should be true
  webSecurity: true     // Should be true
}
```

## Quick Fixes

### Fix 1: Restart Electron App
Sometimes a simple restart fixes issues:
```powershell
# Stop the app (Ctrl+C)
# Restart
npm start
```

### Fix 2: Clear Cache
Clear Electron cache:
```powershell
Remove-Item -Recurse -Force "$env:APPDATA\mediabox-v2-electron"
```

### Fix 3: Reinstall Dependencies
```powershell
npm install
```

### Fix 4: Check preload.js
Verify `preload.js` exists and is correct:
```powershell
Get-Content preload.js
```

## Expected Behavior

### Success:
1. Click service button (e.g., Netflix)
2. Console shows: `[PiP] Opening Netflix...`
3. Console shows: `[PiP] Electron mode - embedding in iframe`
4. Console shows: `[PiP] Viewport found, creating iframe`
5. Console shows: `[PiP] Setting iframe src to: https://...`
6. Console shows: `[PiP] Iframe loaded successfully`
7. Preview box shows the service
8. Status shows: "Netflix loaded in preview box"

### Failure:
1. Click service button
2. Console shows error
3. Preview box shows: "Failed to load [service]"
4. Status shows: "Failed to load [service]"

## Report Issues

If still having issues, provide:
1. Console logs (copy all `[PiP]` messages)
2. Error messages
3. Screenshot of preview box
4. Which service you're trying to open
5. Electron version: `npm list electron`

## Build Info

- **Build**: 16
- **Feature**: Embedded Preview Box
- **Status**: Testing

---

**Note**: This is a debugging guide. Follow steps 1-5 first to identify the issue.

