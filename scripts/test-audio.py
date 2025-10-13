#!/usr/bin/env python3
import subprocess

print("Playing test audio via default sink...")
subprocess.run(["paplay", "/usr/share/sounds/alsa/Front_Center.wav"])
