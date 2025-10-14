const { app, BrowserWindow, ipcMain, screen, globalShortcut } = require('electron');
const path = require('path');
const fs = require('fs');

let mainWindow;
let pipWindow = null;

// Attempt to auto-configure Widevine CDM from Chrome/Edge on Windows
try {
  if (process.platform === 'win32') {
    const localAppData = process.env.LOCALAPPDATA || '';
    const chromeWidevine = path.join(localAppData, 'Google', 'Chrome', 'User Data', 'WidevineCdm');
    const edgeWidevine = path.join(localAppData, 'Microsoft', 'Edge', 'User Data', 'WidevineCdm');
    const baseDir = fs.existsSync(chromeWidevine) ? chromeWidevine : (fs.existsSync(edgeWidevine) ? edgeWidevine : null);

    if (baseDir) {
      const versions = fs.readdirSync(baseDir).filter(v => /^(\d+\.){3}\d+$/.test(v));
      versions.sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
      const version = versions[versions.length - 1];
      if (version) {
        const dllPath = path.join(baseDir, version, '_platform_specific', 'win_x64', 'widevinecdm.dll');
        if (fs.existsSync(dllPath)) {
          app.commandLine.appendSwitch('widevine-cdm-path', dllPath);
          app.commandLine.appendSwitch('widevine-cdm-version', version);
          console.log('[Main] Widevine configured from:', dllPath, 'version:', version);
        }
      }
    } else {
      console.warn('[Main] WidevineCdm folder not found in Chrome/Edge profile');
    }
  }
} catch (e) {
  console.warn('[Main] Widevine auto-config failed:', e);
}

// Enable protected content playback for DRM (Netflix, Prime Video, etc.)
app.commandLine.appendSwitch('enable-features', 'WidevineCdm');
app.commandLine.appendSwitch('enable-features', 'WidevineCdmForTesting');
app.commandLine.appendSwitch('enable-features', 'UseChromeOSDirectVideoDecoder');
app.commandLine.appendSwitch('enable-features', 'HardwareMediaKeyHandling');
app.commandLine.appendSwitch('enable-features', 'MediaFoundationH264Encoding');
app.commandLine.appendSwitch('enable-features', 'PlatformEncryptedDolbyVision');
app.commandLine.appendSwitch('enable-features', 'PlatformEncryptedHEVC');
app.commandLine.appendSwitch('enable-features', 'PlatformEncryptedAV1');

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1920,
    height: 1080,
    fullscreen: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      plugins: true, // Enable plugins for DRM
      webSecurity: true // Keep web security enabled
    },
    icon: path.join(__dirname, 'build', 'icon.png'),
    title: 'MediaBox AI',
    autoHideMenuBar: true
  });

  // Load the dashboard
  mainWindow.loadFile('dashboard/index.html');

  // Set a modern desktop UA to align with DRM storefronts
  try {
    mainWindow.webContents.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    );
  } catch {}

  // Help DRM pipelines by preventing screen capture on the main surface
  try {
    mainWindow.setContentProtection(true);
  } catch (err) {
    console.warn('[Main] setContentProtection on mainWindow failed:', err);
  }

  // Open DevTools in development
  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  // Enable protected content in session
  const { session } = require('electron');
  const ses = session.defaultSession;
  
  // Allow all media permissions
  ses.setPermissionRequestHandler((webContents, permission, callback) => {
    console.log(`[Main] Permission: ${permission}`);
    callback(true); // Allow all permissions
  });
  
  console.log('[Main] Session configured, creating window');
  createWindow();

  // Register global shortcuts for mini-player controls
  try {
    globalShortcut.register('Control+Shift+M', () => {
      if (pipWindow) {
        if (pipWindow.isFullScreen()) {
          pipWindow.setFullScreen(false);
          // Snap to bottom-right on exit
          const b = computeCornerBounds('br');
          pipWindow.setBounds(b);
          pipWindow.setAlwaysOnTop(true);
        } else {
          pipWindow.setFullScreen(true);
        }
      }
    });

    globalShortcut.register('Control+Shift+1', () => { if (pipWindow) pipWindow.setBounds(computeCornerBounds('tl')); });
    globalShortcut.register('Control+Shift+2', () => { if (pipWindow) pipWindow.setBounds(computeCornerBounds('tr')); });
    globalShortcut.register('Control+Shift+3', () => { if (pipWindow) pipWindow.setBounds(computeCornerBounds('bl')); });
    globalShortcut.register('Control+Shift+4', () => { if (pipWindow) pipWindow.setBounds(computeCornerBounds('br')); });
  } catch (err) {
    console.warn('[Main] Failed to register global shortcuts:', err);
  }
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

app.on('will-quit', () => {
  try {
    globalShortcut.unregisterAll();
  } catch (err) {
    console.warn('[Main] Failed to unregister shortcuts:', err);
  }
});

// IPC handlers for system controls
ipcMain.handle('get-audio-devices', async () => {
  // TODO: Implement audio device enumeration
  return [];
});

ipcMain.handle('set-volume', async (event, volume) => {
  // TODO: Implement volume control
  return { success: true };
});

ipcMain.handle('system-action', async (event, action) => {
  // TODO: Implement system actions (shutdown, restart)
  console.log(`System action requested: ${action}`);
  return { success: true };
});

// PiP Window Management
ipcMain.handle('create-pip-window', async (event, { url, serviceName, bounds }) => {
  try {
    console.log('[Main] Creating PIP window:', { url, serviceName, bounds });
    
    // Close existing PiP window if open
    if (pipWindow) {
      console.log('[Main] Closing existing PIP window');
      pipWindow.close();
      pipWindow = null;
    }

    // Create new PiP window as a DRM-safe mini player (not PiP API)
    console.log('[Main] Creating new BrowserWindow');
    pipWindow = new BrowserWindow({
      width: bounds.width,
      height: bounds.height,
      x: bounds.x,
      y: bounds.y,
      // No parent: keep as top-level for robust DRM surface
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js'),
        plugins: true,
        webSecurity: true
      },
      backgroundColor: '#000000',
      frame: false,            // treat as a mini-player surface
      transparent: false,
      alwaysOnTop: true,
      resizable: true,
      movable: true,
      hasShadow: false,
      skipTaskbar: true,
      title: `${serviceName} - Mini Player`
    });

    // Set a modern desktop UA that Netflix supports (avoid mobile UAs)
    try {
      pipWindow.webContents.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
      );
    } catch (err) {
      console.warn('[Main] setUserAgent failed on pipWindow:', err);
    }

    // Align with protected-path expectations (prevents capture)
    try {
      pipWindow.setContentProtection(true);
    } catch (err) {
      console.warn('[Main] setContentProtection failed on pipWindow:', err);
    }

    // Allow sites to open auth/popout windows as needed
    try {
      pipWindow.webContents.setWindowOpenHandler(() => ({ action: 'allow' }));
    } catch (err) {
      console.warn('[Main] setWindowOpenHandler failed on pipWindow:', err);
    }

    console.log('[Main] PIP window created, loading URL');
    
    // Load the URL
    await pipWindow.loadURL(url);
    
    console.log('[Main] URL loaded, setting up event listeners');

    // Handle window close
    pipWindow.on('closed', () => {
      console.log('[Main] PIP window closed');
      pipWindow = null;
      // Notify renderer
      if (mainWindow && !mainWindow.isDestroyed()) {
        mainWindow.webContents.send('pip-window-closed');
      }
    });

    // Handle window move/resize
    pipWindow.on('move', () => {
      if (pipWindow && mainWindow && !mainWindow.isDestroyed()) {
        const newBounds = pipWindow.getBounds();
        mainWindow.webContents.send('pip-window-moved', newBounds);
      }
    });

    pipWindow.on('resize', () => {
      if (pipWindow && mainWindow && !mainWindow.isDestroyed()) {
        const newBounds = pipWindow.getBounds();
        mainWindow.webContents.send('pip-window-resized', newBounds);
      }
    });

    console.log('[Main] PIP window setup complete');
    return { success: true };
  } catch (error) {
    console.error('[Main] Error creating PIP window:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('close-pip-window', async () => {
  try {
    console.log('[Main] Closing PIP window');
    if (pipWindow) {
      pipWindow.close();
      pipWindow = null;
      console.log('[Main] PIP window closed successfully');
      return { success: true };
    }
    console.log('[Main] No PIP window to close');
    return { success: false };
  } catch (error) {
    console.error('[Main] Error closing PIP window:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('expand-pip-window', async () => {
  try {
    console.log('[Main] Expanding PIP window to fullscreen');
    if (pipWindow) {
      const primaryDisplay = screen.getPrimaryDisplay();
      const { width, height } = primaryDisplay.workAreaSize;
      
      pipWindow.setBounds({
        x: 0,
        y: 0,
        width: width,
        height: height
      });
      
      pipWindow.setFullScreen(true);
      console.log('[Main] PIP window expanded successfully');
      return { success: true };
    }
    console.log('[Main] No PIP window to expand');
    return { success: false };
  } catch (error) {
    console.error('[Main] Error expanding PIP window:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('reposition-pip-window', async (event, bounds) => {
  try {
    console.log('[Main] Repositioning PIP window to:', bounds);
    if (pipWindow) {
      pipWindow.setBounds(bounds);
      console.log('[Main] PIP window repositioned successfully');
      return { success: true };
    }
    console.log('[Main] No PIP window to reposition');
    return { success: false };
  } catch (error) {
    console.error('[Main] Error repositioning PIP window:', error);
    return { success: false, error: error.message };
  }
});

// Helper to compute mini-player bounds for a screen corner
function computeCornerBounds(corner) {
  const primaryDisplay = screen.getPrimaryDisplay();
  const wa = primaryDisplay.workArea; // { x, y, width, height }
  const width = 480;
  const height = 270;
  const margin = 16;

  const positions = {
    tl: { x: wa.x + margin, y: wa.y + margin },
    tr: { x: wa.x + wa.width - width - margin, y: wa.y + margin },
    bl: { x: wa.x + margin, y: wa.y + wa.height - height - margin },
    br: { x: wa.x + wa.width - width - margin, y: wa.y + wa.height - height - margin }
  };
  const pos = positions[corner] || positions.br;
  return { x: pos.x, y: pos.y, width, height };
}

// IPC: Toggle mini/full for PiP window
ipcMain.handle('toggle-pip-mini', async () => {
  try {
    if (!pipWindow) return { success: false, error: 'No PiP window' };
    if (pipWindow.isFullScreen()) {
      pipWindow.setFullScreen(false);
      const b = computeCornerBounds('br');
      pipWindow.setBounds(b);
      pipWindow.setAlwaysOnTop(true);
    } else {
      pipWindow.setFullScreen(true);
    }
    return { success: true };
  } catch (error) {
    console.error('[Main] Error toggling mini:', error);
    return { success: false, error: error.message };
  }
});

// IPC: Snap PiP window to a given corner
ipcMain.handle('snap-pip-corner', async (event, corner) => {
  try {
    if (!pipWindow) return { success: false, error: 'No PiP window' };
    pipWindow.setFullScreen(false);
    pipWindow.setBounds(computeCornerBounds(corner));
    pipWindow.setAlwaysOnTop(true);
    return { success: true };
  } catch (error) {
    console.error('[Main] Error snapping corner:', error);
    return { success: false, error: error.message };
  }
});
