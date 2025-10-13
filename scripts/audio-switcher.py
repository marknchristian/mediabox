#!/usr/bin/env python3
"""
Audio Switcher - PulseAudio sink management tool
Supports auto-detection, selection by name or index, and programmatic control
"""
import subprocess
import sys
import json
import argparse


class AudioSwitcher:
    def __init__(self):
        self.sinks = []
        self.current_sink = None
    
    def get_sinks(self):
        """Get list of all available audio sinks"""
        try:
            result = subprocess.run(
                ["pactl", "list", "short", "sinks"], 
                capture_output=True, 
                text=True,
                check=True
            )
            
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
        except subprocess.CalledProcessError as e:
            print(f"Error getting sinks: {e}", file=sys.stderr)
            return []
    
    def get_default_sink(self):
        """Get the current default sink"""
        try:
            result = subprocess.run(
                ["pactl", "get-default-sink"], 
                capture_output=True, 
                text=True,
                check=True
            )
            self.current_sink = result.stdout.strip()
            return self.current_sink
        except subprocess.CalledProcessError as e:
            print(f"Error getting default sink: {e}", file=sys.stderr)
            return None
    
    def get_sink_details(self, sink_name):
        """Get detailed information about a specific sink"""
        try:
            result = subprocess.run(
                ["pactl", "list", "sinks"], 
                capture_output=True, 
                text=True,
                check=True
            )
            
            # Parse the detailed output
            sinks_info = result.stdout.split("Sink #")
            for sink_block in sinks_info[1:]:
                if sink_name in sink_block:
                    return sink_block
            
            return None
        except subprocess.CalledProcessError as e:
            print(f"Error getting sink details: {e}", file=sys.stderr)
            return None
    
    def list_sinks(self, detailed=False, json_output=False):
        """List all available sinks"""
        self.get_sinks()
        current = self.get_default_sink()
        
        if json_output:
            output = {
                'current': current,
                'sinks': self.sinks
            }
            print(json.dumps(output, indent=2))
            return
        
        if not self.sinks:
            print("No audio sinks found!")
            return
        
        print("\n🔊 Available Audio Outputs:\n")
        for i, sink in enumerate(self.sinks):
            is_current = "✓" if sink['name'] == current else " "
            print(f"[{i}] {is_current} {sink['name']}")
            if detailed:
                print(f"    Driver: {sink['driver']}")
                print(f"    State: {sink['state']}")
        
        print(f"\n💡 Current default: {current}\n")
    
    def switch_sink_by_index(self, index):
        """Switch to sink by index number"""
        self.get_sinks()
        
        try:
            index = int(index)
            if 0 <= index < len(self.sinks):
                target_name = self.sinks[index]['name']
                return self.switch_sink_by_name(target_name)
            else:
                print(f"Error: Index {index} out of range (0-{len(self.sinks)-1})", file=sys.stderr)
                return False
        except (ValueError, IndexError) as e:
            print(f"Error: Invalid index - {e}", file=sys.stderr)
            return False
    
    def switch_sink_by_name(self, name):
        """Switch to sink by exact name match"""
        try:
            subprocess.run(
                ["pactl", "set-default-sink", name],
                check=True,
                capture_output=True
            )
            print(f"✓ Switched to: {name}")
            
            # Also move all existing streams to the new sink
            self.move_all_streams_to_sink(name)
            
            return True
        except subprocess.CalledProcessError as e:
            print(f"Error switching sink: {e}", file=sys.stderr)
            return False
    
    def switch_sink_by_pattern(self, pattern):
        """Switch to first sink matching pattern (case-insensitive)"""
        self.get_sinks()
        pattern = pattern.lower()
        
        for sink in self.sinks:
            if pattern in sink['name'].lower():
                return self.switch_sink_by_name(sink['name'])
        
        print(f"Error: No sink found matching '{pattern}'", file=sys.stderr)
        print("\nAvailable sinks:")
        self.list_sinks()
        return False
    
    def move_all_streams_to_sink(self, sink_name):
        """Move all current audio streams to the specified sink"""
        try:
            # Get all sink inputs (active streams)
            result = subprocess.run(
                ["pactl", "list", "short", "sink-inputs"],
                capture_output=True,
                text=True,
                check=True
            )
            
            for line in result.stdout.strip().split("\n"):
                if line:
                    stream_id = line.split()[0]
                    subprocess.run(
                        ["pactl", "move-sink-input", stream_id, sink_name],
                        capture_output=True
                    )
        except subprocess.CalledProcessError:
            # Silently ignore errors (e.g., if no streams are playing)
            pass
    
    def set_volume(self, volume_percent):
        """Set volume for the default sink (0-100%)"""
        try:
            volume_percent = max(0, min(100, int(volume_percent)))
            subprocess.run(
                ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{volume_percent}%"],
                check=True
            )
            print(f"✓ Volume set to {volume_percent}%")
            return True
        except (subprocess.CalledProcessError, ValueError) as e:
            print(f"Error setting volume: {e}", file=sys.stderr)
            return False
    
    def get_volume(self):
        """Get current volume of default sink"""
        try:
            result = subprocess.run(
                ["pactl", "get-sink-volume", "@DEFAULT_SINK@"],
                capture_output=True,
                text=True,
                check=True
            )
            # Parse output like "Volume: front-left: 32768 /  50% / -18.06 dB"
            for part in result.stdout.split():
                if '%' in part:
                    return int(part.replace('%', ''))
            return None
        except subprocess.CalledProcessError as e:
            print(f"Error getting volume: {e}", file=sys.stderr)
            return None
    
    def interactive_mode(self):
        """Interactive mode for selecting audio output"""
        self.list_sinks()
        
        while True:
            try:
                choice = input("\n📍 Select audio output by index (or 'q' to quit): ").strip()
                
                if choice.lower() in ('q', 'quit', 'exit'):
                    print("Goodbye!")
                    break
                
                if self.switch_sink_by_index(choice):
                    print("\n✓ Audio output changed successfully!")
                    break
            except KeyboardInterrupt:
                print("\n\nInterrupted.")
                sys.exit(0)


def main():
    parser = argparse.ArgumentParser(
        description="Audio Switcher - Manage PulseAudio sinks",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s list                    # List all audio outputs
  %(prog)s list --json             # List in JSON format
  %(prog)s switch --index 0        # Switch by index
  %(prog)s switch --name hdmi      # Switch by name pattern
  %(prog)s volume --set 75         # Set volume to 75%%
  %(prog)s volume --get            # Get current volume
  %(prog)s                         # Interactive mode
        """
    )
    
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List available audio sinks')
    list_parser.add_argument('--detailed', '-d', action='store_true', help='Show detailed information')
    list_parser.add_argument('--json', '-j', action='store_true', help='Output as JSON')
    
    # Switch command
    switch_parser = subparsers.add_parser('switch', help='Switch audio output')
    switch_group = switch_parser.add_mutually_exclusive_group(required=True)
    switch_group.add_argument('--index', '-i', type=int, help='Switch by index number')
    switch_group.add_argument('--name', '-n', type=str, help='Switch by name (pattern match)')
    
    # Volume command
    volume_parser = subparsers.add_parser('volume', help='Control volume')
    volume_group = volume_parser.add_mutually_exclusive_group(required=True)
    volume_group.add_argument('--set', '-s', type=int, metavar='PERCENT', help='Set volume (0-100)')
    volume_group.add_argument('--get', '-g', action='store_true', help='Get current volume')
    
    args = parser.parse_args()
    
    switcher = AudioSwitcher()
    
    if args.command == 'list':
        switcher.list_sinks(detailed=args.detailed, json_output=args.json)
    
    elif args.command == 'switch':
        if args.index is not None:
            success = switcher.switch_sink_by_index(args.index)
            sys.exit(0 if success else 1)
        elif args.name:
            success = switcher.switch_sink_by_pattern(args.name)
            sys.exit(0 if success else 1)
    
    elif args.command == 'volume':
        if args.get:
            volume = switcher.get_volume()
            if volume is not None:
                print(f"Current volume: {volume}%")
            else:
                sys.exit(1)
        elif args.set is not None:
            success = switcher.set_volume(args.set)
            sys.exit(0 if success else 1)
    
    else:
        # No command specified - run interactive mode
        switcher.interactive_mode()


if __name__ == "__main__":
    main()
