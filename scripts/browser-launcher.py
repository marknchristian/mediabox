#!/usr/bin/env python3
import subprocess
import sys

apps = {
    'livetv': 'app://iptv',
    'smarthome': 'http://localhost:8123',
    "menu": "file:///home/mediabox/dashboard/index.html",
    "netflix": "https://www.netflix.com",
    "plex": "https://app.plex.tv",
    "amazon": "https://www.amazon.com/Prime-Video"
}

mode = "window"  # or 'kiosk'

def launch(name):
    url = apps.get(name)
    if not url:
        print(f"No app found for {name}")
        return

    flags = ["--new-window", "--start-maximized"]
    if mode == "kiosk":
        flags = ["--kiosk"]

    subprocess.Popen(["chromium-browser"] + flags + [url])

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: browser-launcher.py [menu|netflix|plex|amazon]")
    else:
        launch(sys.argv[1])
