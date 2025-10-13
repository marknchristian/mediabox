#!/usr/bin/env python3
from evdev import InputDevice, categorize, ecodes
import subprocess

# Replace with correct event device after checking with `ir-keytable`
device_path = '/dev/input/event3'

try:
    dev = InputDevice(device_path)
    print(f"Listening on {dev.name}...")

    for event in dev.read_loop():
        if event.type == ecodes.EV_KEY:
            key = categorize(event).keycode
            if event.value == 1:  # key down
                print(f"Pressed: {key}")
                if key == 'KEY_VOLUMEUP':
                    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%"])
                elif key == 'KEY_VOLUMEDOWN':
                    subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%"])
                elif key == 'KEY_MUTE':
                    subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                elif key == 'KEY_POWER':
                    subprocess.run(["shutdown", "-h", "now"])
                elif key == 'KEY_TV':
                    subprocess.run(["python3", "/home/mediabox/scripts/audio-switcher.py"])
except FileNotFoundError:
    print(f"Device {device_path} not found. Use `ir-keytable` to identify the correct eventX.")
