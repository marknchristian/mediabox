# How to Update the Build Number

Every time you make changes to MediaBox AI, update the build number to track versions.

## Location

Edit: `scripts/dashboard-api.py`

Lines 15-16:
```python
VERSION = "1.0.0"
BUILD_NUMBER = "2025.10.11.001"  # Format: YYYY.MM.DD.XXX
```

## How to Update

### Version Number (Major Changes)
Change `VERSION` for major releases:
- `1.0.0` → `1.1.0` (new features)
- `1.1.0` → `2.0.0` (major redesign)

### Build Number (Every Change)
Update `BUILD_NUMBER` for ANY change:

**Format:** `YYYY.MM.DD.XXX`
- `YYYY` = Year (2025)
- `MM` = Month (10)
- `DD` = Day (11)
- `XXX` = Build count for that day (001, 002, 003...)

**Examples:**
```python
BUILD_NUMBER = "2025.10.11.001"  # First build on Oct 11, 2025
BUILD_NUMBER = "2025.10.11.002"  # Second build same day
BUILD_NUMBER = "2025.10.12.001"  # First build on Oct 12, 2025
```

## Auto-Reload

Since Flask is in development mode, just:
1. Edit the build number
2. Save the file
3. Wait 1-2 seconds for Flask to restart
4. Refresh your browser

The new build number will appear at the bottom of the dashboard in **large blue text**!

## Quick Update Command

You can also quickly check the current build:
```bash
curl http://localhost:8080/api/version
```

Returns:
```json
{
  "success": true,
  "version": "1.0.0",
  "build": "2025.10.11.001",
  "service": "MediaBox Dashboard API"
}
```

## Where It Appears

The build number is displayed at the bottom of the dashboard:
- **Version** on the left (smaller text)
- **Build Number** on the right (large blue glowing text)

Example display:
```
Version 1.0.0                    Build 2025.10.11.001
```

