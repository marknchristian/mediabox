const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Audio and system controls
  getAudioDevices: () => ipcRenderer.invoke('get-audio-devices'),
  setVolume: (volume) => ipcRenderer.invoke('set-volume', volume),
  systemAction: (action) => ipcRenderer.invoke('system-action', action),
  platform: process.platform,
  versions: process.versions,
  
  // PIP Window Management
  createPiPWindow: (url, serviceName, bounds) => ipcRenderer.invoke('create-pip-window', { url, serviceName, bounds }),
  closePiPWindow: () => ipcRenderer.invoke('close-pip-window'),
  expandPiPWindow: () => ipcRenderer.invoke('expand-pip-window'),
  repositionPiPWindow: (bounds) => ipcRenderer.invoke('reposition-pip-window', bounds),
  togglePiPMini: () => ipcRenderer.invoke('toggle-pip-mini'),
  snapPiPCorner: (corner) => ipcRenderer.invoke('snap-pip-corner', corner),
  openExternal: (url) => ipcRenderer.invoke('open-external', url),
  
  // Listen for PIP window events
  onPiPWindowClosed: (callback) => ipcRenderer.on('pip-window-closed', callback),
  onPiPWindowMoved: (callback) => ipcRenderer.on('pip-window-moved', callback),
  onPiPWindowResized: (callback) => ipcRenderer.on('pip-window-resized', callback),
  
  // Remove listeners
  removePiPWindowListeners: () => {
    ipcRenderer.removeAllListeners('pip-window-closed');
    ipcRenderer.removeAllListeners('pip-window-moved');
    ipcRenderer.removeAllListeners('pip-window-resized');
  }
});

