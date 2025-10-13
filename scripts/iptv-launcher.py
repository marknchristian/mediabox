#!/usr/bin/env python3
"""
IPTV Launcher for MediaBox AI
Launches IPTV streaming via VLC or Hypnotix
"""
import os
import sys
import subprocess
import argparse
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class IPTVLauncher:
    def __init__(self):
        self.vlc_path = self.find_vlc()
        self.hypnotix_path = self.find_hypnotix()
        self.default_m3u = os.path.expanduser('~/iptv/playlist.m3u')
    
    def find_vlc(self):
        """Find VLC executable"""
        try:
            result = subprocess.run(['which', 'vlc'], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        return None
    
    def find_hypnotix(self):
        """Find Hypnotix executable"""
        try:
            result = subprocess.run(['which', 'hypnotix'], capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip()
        except:
            pass
        return None
    
    def launch_with_vlc(self, m3u_url=None, channel=None):
        """Launch IPTV stream with VLC"""
        if not self.vlc_path:
            logger.error("VLC not found. Please install: sudo apt install vlc")
            return False
        
        # Use default M3U if none provided
        if not m3u_url:
            m3u_url = self.default_m3u
        
        logger.info(f"Launching VLC with {m3u_url}")
        
        try:
            # VLC won't run as root, so we need to run it as mediabox user with proper display
            cmd = [
                'su', '-', 'mediabox', '-c',
                f'DISPLAY=:0 vlc --fullscreen --no-video-title-show --quiet {m3u_url}'
            ]
            
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            logger.info("VLC launched successfully as mediabox user")
            return True
        
        except Exception as e:
            logger.error(f"Failed to launch VLC: {e}")
            return False
    
    def launch_with_hypnotix(self):
        """Launch Hypnotix IPTV player"""
        if not self.hypnotix_path:
            logger.error("Hypnotix not found. Please install: sudo apt install hypnotix")
            return False
        
        logger.info("Launching Hypnotix")
        
        try:
            # Set environment variables for proper display
            env = os.environ.copy()
            env['DISPLAY'] = ':0'
            env['QT_QPA_PLATFORM'] = 'xcb'  # Force Qt to use X11
            
            subprocess.Popen(
                [self.hypnotix_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                env=env
            )
            logger.info("Hypnotix launched successfully")
            return True
        
        except Exception as e:
            logger.error(f"Failed to launch Hypnotix: {e}")
            return False
    
    def launch_stream_url(self, stream_url):
        """Launch a direct stream URL with VLC"""
        if not self.vlc_path:
            logger.error("VLC not found")
            return False
        
        logger.info(f"Launching stream: {stream_url}")
        
        try:
            # VLC won't run as root, so we need to run it as mediabox user with proper display
            cmd = [
                'su', '-', 'mediabox', '-c',
                f'DISPLAY=:0 vlc --fullscreen --no-video-title-show --quiet {stream_url}'
            ]
            
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            logger.info("Stream launched successfully as mediabox user")
            return True
        
        except Exception as e:
            logger.error(f"Failed to launch stream: {e}")
            return False
    
    def get_status(self):
        """Get launcher status and available players"""
        return {
            'vlc_available': self.vlc_path is not None,
            'hypnotix_available': self.hypnotix_path is not None,
            'vlc_path': self.vlc_path,
            'hypnotix_path': self.hypnotix_path,
            'default_m3u': self.default_m3u
        }


def main():
    parser = argparse.ArgumentParser(description='IPTV Launcher for MediaBox AI')
    parser.add_argument('--vlc', action='store_true', help='Use VLC player')
    parser.add_argument('--hypnotix', action='store_true', help='Use Hypnotix player')
    parser.add_argument('--m3u', type=str, help='M3U playlist URL or file path')
    parser.add_argument('--stream', type=str, help='Direct stream URL')
    parser.add_argument('--status', action='store_true', help='Show launcher status')
    
    args = parser.parse_args()
    
    launcher = IPTVLauncher()
    
    # Show status
    if args.status:
        import json
        print(json.dumps(launcher.get_status(), indent=2))
        return
    
    # Launch with specific player
    if args.hypnotix:
        success = launcher.launch_with_hypnotix()
    elif args.stream:
        success = launcher.launch_stream_url(args.stream)
    elif args.vlc or args.m3u:
        success = launcher.launch_with_vlc(args.m3u)
    else:
        # Auto-detect: prefer Hypnotix, fallback to VLC
        if launcher.hypnotix_path:
            logger.info("Auto-selecting Hypnotix")
            success = launcher.launch_with_hypnotix()
        elif launcher.vlc_path:
            logger.info("Auto-selecting VLC")
            success = launcher.launch_with_vlc()
        else:
            logger.error("No IPTV player found. Install VLC or Hypnotix.")
            success = False
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
