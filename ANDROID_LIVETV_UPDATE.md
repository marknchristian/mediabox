# Android Live TV Update - MyTvOnline+ Integration

## Summary
Added Android-specific detection and MyTvOnline+ app handling for the Live TV service.

## Changes Made

### 1. OS Detection Functions (scripts/dashboard-api.py)
Added two new helper functions:

- **`detect_os()`**: Detects the operating system type
  - Checks for Android via `/system/build.prop`
  - Checks for Linux via `/proc/version`
  - Checks for Windows and macOS
  - Returns: `'android'`, `'linux'`, `'windows'`, `'macos'`, or `'unknown'`

- **`is_android_app_installed(package_name)`**: Checks if an Android app is installed
  - Uses the `pm list packages` command
  - Returns `True` if app is installed, `False` otherwise

### 2. Live TV Service Logic (scripts/dashboard-api.py)
Updated the `livetv` service handler to:

**For Android systems:**
1. Check if MyTvOnline+ is installed (`com.stalkermiddleware.mytvonline2`)
2. If installed:
   - Launch the app using `am start` command
   - Return success message: "MyTvOnline+ launched successfully"
   - Console log: `[INFO] Invoking MyTvOnline+ on Android platform`
   - Console log: `[INFO] MyTvOnline+ found, launching app`
   - Console log: `[SUCCESS] MyTvOnline+ launched successfully`
3. If not installed:
   - Open Google Play Store to the MyTvOnline+ app page
   - Return message: "Install MyTvOnline+ - Play Store opened"
   - Console log: `[WARNING] MyTvOnline+ not installed, opening Play Store`
   - Console log: `[INFO] Play Store opened for MyTvOnline+ installation`
   - If Play Store can't be opened, return error: "Install MyTvOnline+ - Could not open Play Store"
   - Console log: `[ERROR] Could not open Play Store for MyTvOnline+`

**For non-Android systems (Linux, etc.):**
- Use existing VLC-based IPTV launcher
- Maintains backward compatibility with existing functionality

### 3. Response Messages
The API now returns platform-specific messages:
- `message`: User-friendly message about what happened
- `platform`: OS type detected (`'android'`, `'linux'`, etc.)
- `action`: Additional context (`'install'`, `'install_required'`)
- `fallback`: Boolean flag (for Plexamp fallback to Plex)

## API Response Examples

### Android - App Installed
```json
{
  "success": true,
  "message": "MyTvOnline+ launched successfully",
  "platform": "android"
}
```
Console output:
```
[INFO] Invoking MyTvOnline+ on Android platform
[INFO] MyTvOnline+ found, launching app
[SUCCESS] MyTvOnline+ launched successfully
```

### Android - App Not Installed
```json
{
  "success": true,
  "message": "Install MyTvOnline+ - Play Store opened",
  "platform": "android",
  "action": "install"
}
```
Console output:
```
[INFO] Invoking MyTvOnline+ on Android platform
[WARNING] MyTvOnline+ not installed, opening Play Store
[INFO] Play Store opened for MyTvOnline+ installation
```

### Android - Play Store Failed
```json
{
  "success": false,
  "error": "Install MyTvOnline+ - Could not open Play Store",
  "platform": "android",
  "action": "install_required"
}
```
Console output:
```
[INFO] Invoking MyTvOnline+ on Android platform
[WARNING] MyTvOnline+ not installed, opening Play Store
[ERROR] Failed to open Play Store: <error details>
[ERROR] Could not open Play Store for MyTvOnline+
```

### Non-Android (Linux)
```json
{
  "success": true,
  "message": "Live TV (IPTV) launched successfully with VLC",
  "platform": "linux"
}
```

## Testing Recommendations

1. **Android Device Testing:**
   - Test with MyTVOnline+ installed
   - Test with MyTVOnline+ NOT installed
   - Verify Play Store opens correctly
   - Verify app launches when installed

2. **Linux/Docker Testing:**
   - Verify VLC launcher still works
   - Ensure no Android-specific code interferes

3. **Error Handling:**
   - Test with no internet (Play Store won't open)
   - Test with invalid package ID
   - Test with Android but no `pm` command available

## Package Information

- **App Name**: MyTvOnline+
- **Package ID**: `com.stalkermiddleware.mytvonline2`
- **Play Store URL**: `market://details?id=com.stalkermiddleware.mytvonline2`
- **App Launch Command**: `am start -n com.stalkermiddleware.mytvonline2/.MainActivity`

## Frontend Compatibility

**Important**: The frontend (`dashboard/index.html`) has been updated to **always call the backend API** for Live TV instead of using direct Android app launch methods. This ensures:

1. Proper OS detection (Android vs Linux)
2. MyTvOnline+ installation checking
3. Graceful fallback to Play Store if not installed
4. Consistent behavior across all platforms

The frontend no longer uses the `openAndroidAppOrWeb()` function for Live TV - it now exclusively uses the backend API endpoint `/api/launch/livetv`.

## Related Files Modified

- `scripts/dashboard-api.py` - Main API server with OS detection and Live TV logic
- `dashboard/index.html` - Frontend updated to call backend API for Live TV instead of direct Android app launch

## Notes

- **App Name**: The app is consistently referred to as "MyTvOnline+" throughout the codebase
- **Console Logging**: All invocations write detailed console messages with `print()` statements for easy debugging:
  - `[INFO]` for informational messages
  - `[WARNING]` for non-critical issues
  - `[SUCCESS]` for successful operations
  - `[ERROR]` for failures
- The package ID `com.stalkermiddleware.mytvonline2` matches the frontend configuration
- The implementation gracefully falls back to VLC for non-Android systems
- All error cases are handled with appropriate user-facing messages
- Logging is comprehensive for debugging Android-specific issues

