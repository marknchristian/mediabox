#!/usr/bin/env python3
"""
MediaBox AI Dashboard API Server
Flask-based REST API for controlling the media center
"""
import os
import sys
import subprocess
import logging
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import json

# MediaBox AI Version/Build Number
VERSION = "1.0.0"
BUILD_NUMBER = "2025.01.15.010"  # Format: YYYY.MM.DD.XXX - Build 10

# Home Assistant Configuration
# To enable auto-login, create a long-lived access token in Home Assistant:
# 1. Go to Home Assistant -> Profile -> Long-Lived Access Tokens
# 2. Create a token named "MediaBox AI Dashboard"
# 3. Copy the token and set it in the environment variable HASS_TOKEN
HASS_USERNAME = os.environ.get('HASS_USERNAME', 'threefingers')
HASS_PASSWORD = os.environ.get('HASS_PASSWORD', 'threefingers')
HASS_TOKEN = os.environ.get('HASS_TOKEN', '')  # Long-lived access token (recommended)

# Import the AudioSwitcher class
# Add scripts directory to path so we can import audio_switcher
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

# Define a minimal AudioSwitcher class for when audio is not available
class AudioSwitcher:
    """Minimal audio switcher that handles missing audio gracefully"""
    def __init__(self):
        self.sinks = []
        self.current_sink = None
        try:
            result = subprocess.run(["pactl", "list", "short", "sinks"], 
                                  capture_output=True, text=True, timeout=2)
            if result.returncode != 0:
                raise Exception("PulseAudio not available")
        except:
            raise Exception("Audio system not available")
    
    def get_sinks(self):
        result = subprocess.run(["pactl", "list", "short", "sinks"], 
                              capture_output=True, text=True, check=True)
        self.sinks = []
        for line in result.stdout.strip().split("\n"):
            if line:
                parts = line.split()
                if len(parts) >= 2:
                    self.sinks.append({
                        'index': parts[0],
                        'name': parts[1],
                        'driver': parts[2] if len(parts) > 2 else 'unknown',
                        'state': parts[3] if len(parts) > 3 else 'unknown'
                    })
        return self.sinks
    
    def get_default_sink(self):
        result = subprocess.run(["pactl", "get-default-sink"], 
                              capture_output=True, text=True, check=True)
        self.current_sink = result.stdout.strip()
        return self.current_sink
    
    def switch_sink_by_pattern(self, pattern):
        self.get_sinks()
        pattern = pattern.lower()
        for sink in self.sinks:
            if pattern in sink['name'].lower():
                subprocess.run(["pactl", "set-default-sink", sink['name']], check=True)
                return True
        return False
    
    def set_volume(self, volume_percent):
        volume_percent = max(0, min(100, int(volume_percent)))
        subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{volume_percent}%"], check=True)
        return True
    
    def get_volume(self):
        result = subprocess.run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
                              capture_output=True, text=True, check=True)
        for part in result.stdout.split():
            if '%' in part:
                return int(part.replace('%', ''))
        return None

# Initialize Flask app
# Set template and static folders to dashboard directory
dashboard_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'dashboard')
app = Flask(__name__, 
            static_folder=dashboard_dir,
            static_url_path='')
CORS(app)  # Enable CORS for frontend access

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize audio switcher (may fail on systems without audio)
try:
    audio_switcher = AudioSwitcher()
    logger.info("Audio switcher initialized successfully")
except Exception as e:
    audio_switcher = None
    logger.warning(f"Audio switcher initialization failed (expected on Windows Docker): {e}")

# Service URLs for streaming platforms
SERVICE_URLS = {
    'netflix': 'https://www.netflix.com',
    'amazon': 'https://www.primevideo.com/collection/IncludedwithPrime',
    'youtube': 'https://www.youtube.com',
    'plex': 'http://netlite.community:32400/web/index.html',  # Remote Plex server
    'livetv': 'iptv',  # Will launch Hypnotix
    'smarthome': 'http://localhost:8123',  # Home Assistant
    'news': 'https://www.bbc.com/news',  # BBC News - clean, TV-friendly layout
    'telegram': 'https://web.telegram.org',
    'calendar': 'https://outlook.office.com/bookings/calendar'  # Outlook Bookings Calendar
}


# ==================== DASHBOARD FRONTEND ====================

@app.route('/')
def serve_dashboard():
    """Serve the main dashboard HTML page"""
    return send_from_directory(dashboard_dir, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files from dashboard directory"""
    return send_from_directory(dashboard_dir, path)


# ==================== LAUNCH ENDPOINTS ====================

@app.route('/api/launch/<service>', methods=['POST'])
def launch_service(service):
    """Launch a streaming service or application"""
    try:
        service = service.lower()
        logger.info(f"Launching service: {service}")
        
        if service == 'plex':
            # Launch native Plex HTPC application
            try:
                # Launch Plex HTPC via Flatpak as mediabox user
                subprocess.Popen([
                    'su', '-', 'mediabox', '-c', 
                    'DISPLAY=:0 flatpak run tv.plex.PlexDesktop'
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                logger.info("Plex HTPC launched successfully")
                return jsonify({
                    'success': True,
                    'message': 'Plex HTPC launched successfully'
                })
                
            except Exception as e:
                logger.error(f"Error launching Plex HTPC: {e}")
                return jsonify({
                    'success': False,
                    'error': f'Failed to launch Plex HTPC: {e}'
                }), 500
        
        elif service == 'plexamp':
            # Launch native Plexamp application with fallback to Plex
            try:
                # First, check if Plexamp is installed
                check_result = subprocess.run([
                    'flatpak', 'info', 'com.plexamp.Plexamp'
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                if check_result.returncode != 0:
                    # Plexamp not installed, launch Plex as fallback
                    logger.warning("Plexamp not installed, launching Plex as fallback")
                    subprocess.Popen([
                        'su', '-', 'mediabox', '-c', 
                        'DISPLAY=:0 flatpak run tv.plex.PlexDesktop'
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    
                    return jsonify({
                        'success': True,
                        'message': 'Plexamp not installed. Launched Plex as fallback.',
                        'fallback': True
                    })
                
                # Plexamp is installed, launch it
                subprocess.Popen([
                    'su', '-', 'mediabox', '-c', 
                    'DISPLAY=:0 flatpak run com.plexamp.Plexamp'
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                logger.info("Plexamp launched successfully")
                return jsonify({
                    'success': True,
                    'message': 'Plexamp launched successfully'
                })
                
            except Exception as e:
                logger.error(f"Error launching Plexamp: {e}")
                return jsonify({
                    'success': False,
                    'error': f'Failed to launch Plexamp: {e}'
                }), 500
        
        elif service == 'livetv':
            # Launch IPTV application using VLC
            try:
                # Use the IPTV launcher script for better functionality
                iptv_script = os.path.join(script_dir, 'iptv-launcher.py')
                result = subprocess.run([
                    'python3', iptv_script, '--vlc'
                ], capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0:
                    logger.info("IPTV (VLC) launched successfully")
                    return jsonify({
                        'success': True,
                        'message': 'Live TV (IPTV) launched successfully with VLC'
                    })
                else:
                    logger.warning("IPTV launcher failed, trying direct VLC launch")
                    # Fallback to direct VLC launch as mediabox user with VNC display
                    subprocess.Popen([
                        'su', '-', 'mediabox', '-c', 'DISPLAY=:0 vlc --fullscreen --no-video-title-show --quiet'
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    return jsonify({
                        'success': True,
                        'message': 'Live TV (IPTV) launched with VLC via fallback method'
                    })
                    
            except subprocess.TimeoutExpired:
                logger.error("IPTV launcher timed out")
                return jsonify({
                    'success': False,
                    'error': 'IPTV launcher timed out'
                }), 500
            except Exception as e:
                logger.error(f"Error launching IPTV: {e}")
                # Fallback to direct VLC launch as mediabox user with VNC display
                try:
                    subprocess.Popen([
                        'su', '-', 'mediabox', '-c', 'DISPLAY=:0 vlc --fullscreen --no-video-title-show --quiet'
                    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    return jsonify({
                        'success': True,
                        'message': 'Live TV (IPTV) launched with VLC via fallback method'
                    })
                except Exception as fallback_error:
                    return jsonify({
                        'success': False,
                        'error': f'Failed to launch IPTV: {fallback_error}'
                    }), 500
        
        elif service in SERVICE_URLS:
            url = SERVICE_URLS[service]
            
            # For smarthome, use localhost since we're launching from inside the container
            if service == 'smarthome':
                url = 'http://homeassistant:8123'
            # For plexamp, use the dedicated web interface with server connection
            elif service == 'plexamp':
                url = 'https://plexamp.com/web?server=netlite.community:32400'
            
            # Launch Chromium in kiosk mode
            chromium_cmd = [
                'chromium-browser',
                '--kiosk',
                '--disable-infobars',
                '--disable-session-crashed-bubble',
                '--disable-restore-session-state',
                '--app=' + url
            ]
            
            subprocess.Popen(chromium_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
            return jsonify({
                'success': True,
                'message': f'{service.capitalize()} launched',
                'url': url
            })
        
        else:
            return jsonify({
                'success': False,
                'error': f'Unknown service: {service}'
            }), 400
    
    except Exception as e:
        logger.error(f"Error launching {service}: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ==================== AUDIO ENDPOINTS ====================

@app.route('/api/audio-devices', methods=['GET'])
def get_audio_devices():
    """Get list of available audio devices"""
    try:
        if audio_switcher is None:
            return jsonify({
                'success': False,
                'error': 'Audio not available on this system',
                'devices': [],
                'note': 'Audio passthrough not supported on Windows/Mac Docker'
            }), 503
        
        audio_switcher.get_sinks()
        current = audio_switcher.get_default_sink()
        
        devices = []
        for i, sink in enumerate(audio_switcher.sinks):
            devices.append({
                'id': sink['name'],
                'name': format_sink_name(sink['name']),
                'index': i,
                'driver': sink['driver'],
                'active': sink['name'] == current
            })
        
        return jsonify({
            'success': True,
            'devices': devices,
            'current': current
        })
    
    except Exception as e:
        logger.error(f"Error getting audio devices: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/switch-audio', methods=['POST'])
def switch_audio():
    """Switch audio output device"""
    try:
        if audio_switcher is None:
            return jsonify({
                'success': False,
                'error': 'Audio not available on this system',
                'note': 'Audio passthrough not supported on Windows/Mac Docker'
            }), 503
        
        data = request.get_json()
        output = data.get('output', '').lower()
        
        logger.info(f"Switching audio to: {output}")
        
        # Map common names to patterns
        audio_patterns = {
            'hdmi': 'hdmi',
            'spdif': 'spdif',
            'optical': 'spdif',
            'coax': 'spdif',
            'analog': 'analog',
            '3.5mm': 'analog'
        }
        
        pattern = audio_patterns.get(output, output)
        
        # Try switching by pattern
        success = audio_switcher.switch_sink_by_pattern(pattern)
        
        if success:
            return jsonify({
                'success': True,
                'message': f'Switched to {output} output',
                'output': pattern
            })
        else:
            return jsonify({
                'success': False,
                'error': f'Failed to switch to {output}'
            }), 400
    
    except Exception as e:
        logger.error(f"Error switching audio: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/volume', methods=['GET', 'POST'])
def volume_control():
    """Get or set volume level"""
    try:
        if audio_switcher is None:
            return jsonify({
                'success': False,
                'error': 'Audio not available on this system',
                'note': 'Audio passthrough not supported on Windows/Mac Docker'
            }), 503
        
        if request.method == 'GET':
            volume = audio_switcher.get_volume()
            if volume is not None:
                return jsonify({
                    'success': True,
                    'volume': volume
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'Could not get volume'
                }), 500
        
        elif request.method == 'POST':
            data = request.get_json()
            volume = data.get('volume')
            
            if volume is None:
                return jsonify({
                    'success': False,
                    'error': 'Volume parameter required'
                }), 400
            
            success = audio_switcher.set_volume(volume)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': f'Volume set to {volume}%',
                    'volume': volume
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'Failed to set volume'
                }), 400
    
    except Exception as e:
        logger.error(f"Error controlling volume: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ==================== SYSTEM ENDPOINTS ====================

@app.route('/api/shutdown', methods=['POST'])
def shutdown_system():
    """Shutdown the system"""
    try:
        logger.warning("Shutdown requested")
        # Use systemctl for proper shutdown
        subprocess.Popen(['systemctl', 'poweroff'])
        
        return jsonify({
            'success': True,
            'message': 'System shutting down...'
        })
    
    except Exception as e:
        logger.error(f"Error during shutdown: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/restart', methods=['POST'])
def restart_system():
    """Restart the system"""
    try:
        logger.warning("Restart requested")
        # Use systemctl for proper restart
        subprocess.Popen(['systemctl', 'reboot'])
        
        return jsonify({
            'success': True,
            'message': 'System restarting...'
        })
    
    except Exception as e:
        logger.error(f"Error during restart: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/status', methods=['GET'])
def get_status():
    """Get system status"""
    try:
        # Get CPU and memory info using psutil
        import psutil
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        
        # Get audio info if available
        audio_info = {}
        if audio_switcher:
            try:
                audio_info['audio_output'] = audio_switcher.get_default_sink()
                audio_info['volume'] = audio_switcher.get_volume()
            except:
                pass
        
        # Get system uptime
        try:
            uptime_result = subprocess.run(['uptime', '-p'], capture_output=True, text=True, timeout=2)
            uptime = uptime_result.stdout.strip() if uptime_result.returncode == 0 else 'Running'
        except:
            uptime = 'Running'
        
        return jsonify({
            'success': True,
            'status': {
                'cpu_percent': round(cpu_percent, 1),
                'memory_percent': round(memory_percent, 1),
                'uptime': uptime,
                **audio_info
            }
        })
    
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ==================== LIGHTING ENDPOINTS ====================

@app.route('/api/lighting/<action>', methods=['POST'])
def control_lighting(action):
    """Control lighting (dim/brighten)"""
    try:
        action = action.lower()
        logger.info(f"Lighting control: {action}")
        
        if action not in ['dim', 'brighten']:
            return jsonify({
                'success': False,
                'error': f'Invalid action: {action}'
            }), 400
        
        # Here you would integrate with your actual light dimmer
        # For now, we'll just log the action
        # You can add Home Assistant integration or direct dimmer control
        
        # Example: Call Home Assistant service
        # import requests
        # ha_url = os.environ.get('HASS_SERVER', 'http://homeassistant:8123')
        # ha_token = os.environ.get('HASS_TOKEN', '')
        # brightness = 30 if action == 'dim' else 255
        # requests.post(f'{ha_url}/api/services/light/turn_on',
        #              headers={'Authorization': f'Bearer {ha_token}'},
        #              json={'entity_id': 'light.living_room', 'brightness': brightness})
        
        return jsonify({
            'success': True,
            'message': f'Lights {"dimmed" if action == "dim" else "brightened"}',
            'action': action
        })
    
    except Exception as e:
        logger.error(f"Error controlling lighting: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ==================== UTILITY ENDPOINTS ====================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'success': True,
        'status': 'healthy',
        'service': 'MediaBox AI Dashboard API',
        'version': VERSION,
        'build': BUILD_NUMBER
    })

@app.route('/api/version', methods=['GET'])
def get_version():
    """Get version and build information"""
    return jsonify({
        'success': True,
        'version': VERSION,
        'build': BUILD_NUMBER,
        'service': 'MediaBox Dashboard API'
    })

@app.route('/api/hass-config', methods=['GET'])
def get_hass_config():
    """Get Home Assistant configuration for auto-login"""
    return jsonify({
        'success': True,
        'username': HASS_USERNAME,
        'password': HASS_PASSWORD,
        'has_token': bool(HASS_TOKEN),
        'token': HASS_TOKEN if HASS_TOKEN else None
    })


@app.route('/api/iptv-status', methods=['GET'])
def get_iptv_status():
    """Check IPTV launcher status and available players"""
    try:
        iptv_script = os.path.join(script_dir, 'iptv-launcher.py')
        result = subprocess.run([
            'python3', iptv_script, '--status'
        ], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            import json
            status_data = json.loads(result.stdout)
            return jsonify({
                'success': True,
                'iptv_status': status_data,
                'available_players': {
                    'vlc': status_data.get('vlc_found', False),
                    'hypnotix': status_data.get('hypnotix_found', False)
                }
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Could not check IPTV status',
                'available_players': {'vlc': False, 'hypnotix': False}
            }), 500
            
    except Exception as e:
        logger.error(f"Error checking IPTV status: {e}")
        return jsonify({
            'success': False,
            'error': str(e),
            'available_players': {'vlc': False, 'hypnotix': False}
        }), 500


@app.route('/api/bbc-news', methods=['GET'])
def get_bbc_news():
    """Fetch BBC news headlines"""
    try:
        import requests
        from bs4 import BeautifulSoup
        import re
        
        # BBC News homepage URL
        bbc_url = "https://www.bbc.com/news"
        
        # Headers to mimic a real browser
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        # Fetch BBC news page
        response = requests.get(bbc_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract headlines from various BBC news sections
        headlines = []
        
        # Main headlines (h1 and h2 tags with specific classes)
        main_headlines = soup.find_all(['h1', 'h2'], class_=re.compile(r'(gs-c-promo-heading|gs-c-promo-title)'))
        for headline in main_headlines[:8]:  # Limit to 8 headlines
            text = headline.get_text(strip=True)
            if text and len(text) > 10:  # Filter out short/empty headlines
                headlines.append(text)
        
        # If we don't have enough headlines, try alternative selectors
        if len(headlines) < 5:
            alt_headlines = soup.find_all('a', href=re.compile(r'/news/'))
            for link in alt_headlines[:10]:
                text = link.get_text(strip=True)
                if text and len(text) > 15 and text not in headlines:
                    headlines.append(text)
                    if len(headlines) >= 8:
                        break
        
        # Remove duplicates and limit
        unique_headlines = []
        seen = set()
        for headline in headlines:
            if headline not in seen and len(headline) > 10:
                unique_headlines.append(headline)
                seen.add(headline)
                if len(unique_headlines) >= 6:
                    break
        
        logger.info(f"Fetched {len(unique_headlines)} BBC news headlines")
        
        return jsonify({
            'success': True,
            'headlines': unique_headlines,
            'source': 'BBC News',
            'count': len(unique_headlines)
        })
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch BBC news: {e}")
        return jsonify({
            'success': False,
            'error': 'Failed to fetch BBC news',
            'headlines': []
        }), 503
    except Exception as e:
        logger.error(f"Error parsing BBC news: {e}")
        return jsonify({
            'success': False,
            'error': 'Error parsing news data',
            'headlines': []
        }), 500


@app.route('/api/', methods=['GET'])
def api_info():
    """API information and available endpoints"""
    endpoints = {
        'launch': {
            'POST /api/launch/<service>': 'Launch a streaming service (netflix, amazon, youtube, plex, plexamp, spotify, livetv, smarthome)'
        },
        'audio': {
            'GET /api/audio-devices': 'Get list of available audio devices',
            'POST /api/switch-audio': 'Switch audio output (body: {"output": "hdmi|spdif|analog"})',
            'GET /api/volume': 'Get current volume level',
            'POST /api/volume': 'Set volume level (body: {"volume": 0-100})'
        },
        'system': {
            'POST /api/shutdown': 'Shutdown the system',
            'POST /api/restart': 'Restart the system',
            'GET /api/status': 'Get system status'
        },
        'utility': {
            'GET /api/health': 'Health check',
            'GET /api/iptv-status': 'Check IPTV launcher status and available players',
            'GET /api/bbc-news': 'Fetch BBC news headlines',
            'GET /api/': 'This help message'
        }
    }
    
    return jsonify({
        'success': True,
        'service': 'MediaBox AI Dashboard API',
        'version': '1.0',
        'endpoints': endpoints
    })


# ==================== HELPER FUNCTIONS ====================

def format_sink_name(sink_name):
    """Format sink name for display"""
    # Extract readable name from PulseAudio sink identifier
    if 'hdmi' in sink_name.lower():
        return 'HDMI Audio'
    elif 'spdif' in sink_name.lower():
        return 'SPDIF (Optical/Coax)'
    elif 'analog' in sink_name.lower():
        return 'Analog Output (3.5mm)'
    elif 'usb' in sink_name.lower():
        return 'USB Audio'
    else:
        # Return cleaned up version
        return sink_name.replace('_', ' ').title()


# ==================== MAIN ====================

if __name__ == '__main__':
    # Get port from environment or default to 8080
    port = int(os.environ.get('PORT', 8080))
    
    # Check if we're in development mode
    dev_mode = os.environ.get('FLASK_ENV', 'development') == 'development'
    
    logger.info("Starting MediaBox AI Dashboard API Server...")
    logger.info(f"Dashboard will be available at http://localhost:{port}/")
    logger.info(f"API will be available at http://localhost:{port}/api/")
    
    if dev_mode:
        logger.info("🔥 Running in DEVELOPMENT mode - Auto-reload enabled!")
        logger.info("📝 File changes will be detected automatically")
    
    # Run Flask server
    app.run(
        host='0.0.0.0',  # Listen on all interfaces
        port=port,
        debug=dev_mode,  # Enable debug mode for auto-reload
        use_reloader=dev_mode,  # Enable reloader
        threaded=True
    )
