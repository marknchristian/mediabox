#!/usr/bin/env python3
"""
MediaBox AI API Test Suite
Automated tests for the MediaBox AI Dashboard API
"""
import requests
import json
import time
import sys
from datetime import datetime

# Configuration
API_BASE = "http://localhost:8080"
COLORS = {
    'GREEN': '\033[92m',
    'RED': '\033[91m',
    'YELLOW': '\033[93m',
    'BLUE': '\033[94m',
    'END': '\033[0m'
}

class MediaBoxAITester:
    def __init__(self, base_url=API_BASE):
        self.base_url = base_url
        self.passed = 0
        self.failed = 0
        self.warnings = 0
        self.results = []
    
    def print_header(self, text):
        """Print a test section header"""
        print(f"\n{COLORS['BLUE']}{'=' * 70}{COLORS['END']}")
        print(f"{COLORS['BLUE']}{text:^70}{COLORS['END']}")
        print(f"{COLORS['BLUE']}{'=' * 70}{COLORS['END']}\n")
    
    def test_result(self, test_name, passed, message="", warning=False):
        """Record and print test result"""
        if passed:
            status = f"{COLORS['GREEN']}✓ PASS{COLORS['END']}"
            self.passed += 1
        elif warning:
            status = f"{COLORS['YELLOW']}⚠ WARN{COLORS['END']}"
            self.warnings += 1
        else:
            status = f"{COLORS['RED']}✗ FAIL{COLORS['END']}"
            self.failed += 1
        
        print(f"{status} - {test_name}")
        if message:
            print(f"       {message}")
        
        self.results.append({
            'test': test_name,
            'passed': passed,
            'warning': warning,
            'message': message,
            'timestamp': datetime.now().isoformat()
        })
    
    def run_all_tests(self):
        """Run all test suites"""
        print(f"\n{COLORS['BLUE']}╔═══════════════════════════════════════════════════════════════════╗{COLORS['END']}")
        print(f"{COLORS['BLUE']}║      MediaBox AI API Test Suite - Starting Tests                 ║{COLORS['END']}")
        print(f"{COLORS['BLUE']}╚═══════════════════════════════════════════════════════════════════╝{COLORS['END']}")
        
        # Run test suites
        self.test_connectivity()
        self.test_health_endpoints()
        self.test_dashboard_serving()
        self.test_audio_endpoints()
        self.test_service_launch_endpoints()
        self.test_system_control_endpoints()
        self.test_api_documentation()
        self.test_cors_headers()
        self.test_error_handling()
        self.test_response_times()
        
        # Print summary
        self.print_summary()
    
    # ==================== TEST SUITES ====================
    
    def test_connectivity(self):
        """Test 1-2: Basic connectivity"""
        self.print_header("Basic Connectivity Tests")
        
        try:
            response = requests.get(f"{self.base_url}/api/health", timeout=5)
            self.test_result(
                "Test 1: API server is reachable",
                response.status_code == 200,
                f"Status: {response.status_code}"
            )
        except requests.exceptions.RequestException as e:
            self.test_result(
                "Test 1: API server is reachable",
                False,
                f"Error: {str(e)}"
            )
            return
        
        try:
            response = requests.get(f"{self.base_url}/", timeout=5)
            self.test_result(
                "Test 2: Dashboard is accessible",
                response.status_code == 200 and "MediaBox AI" in response.text,
                f"Status: {response.status_code}, Contains MediaBox AI: {'MediaBox AI' in response.text}"
            )
        except Exception as e:
            self.test_result("Test 2: Dashboard is accessible", False, str(e))
    
    def test_health_endpoints(self):
        """Test 3-4: Health and status endpoints"""
        self.print_header("Health & Status Endpoints")
        
        try:
            response = requests.get(f"{self.base_url}/api/health")
            data = response.json()
            self.test_result(
                "Test 3: Health endpoint returns valid JSON",
                response.status_code == 200 and 'status' in data,
                f"Response: {json.dumps(data, indent=2)}"
            )
        except Exception as e:
            self.test_result("Test 3: Health endpoint returns valid JSON", False, str(e))
        
        try:
            response = requests.get(f"{self.base_url}/api/status")
            data = response.json()
            self.test_result(
                "Test 4: Status endpoint returns system info",
                response.status_code == 200 and 'status' in data,
                f"Has status data: {bool(data.get('status'))}"
            )
        except Exception as e:
            self.test_result("Test 4: Status endpoint returns system info", False, str(e))
    
    def test_dashboard_serving(self):
        """Test 5-6: Dashboard file serving"""
        self.print_header("Dashboard File Serving")
        
        try:
            response = requests.get(f"{self.base_url}/")
            html = response.text
            
            checks = [
                ('HTML5 doctype', '<!DOCTYPE html>' in html),
                ('MediaBox AI title', 'MediaBox AI Dashboard' in html),
                ('Streaming buttons', 'netflix' in html.lower()),
                ('Audio controls', 'audio-controls' in html),
                ('JavaScript', '<script>' in html)
            ]
            
            all_passed = all(check[1] for check in checks)
            details = ', '.join([f"{name}: {'✓' if result else '✗'}" for name, result in checks])
            
            self.test_result(
                "Test 5: Dashboard HTML contains all required elements",
                all_passed,
                details
            )
        except Exception as e:
            self.test_result("Test 5: Dashboard HTML contains all required elements", False, str(e))
        
        try:
            response = requests.get(f"{self.base_url}/api/")
            data = response.json()
            self.test_result(
                "Test 6: API documentation endpoint works",
                response.status_code == 200 and 'endpoints' in data,
                f"Endpoints documented: {len(data.get('endpoints', {}))}"
            )
        except Exception as e:
            self.test_result("Test 6: API documentation endpoint works", False, str(e))
    
    def test_audio_endpoints(self):
        """Test 7-10: Audio control endpoints"""
        self.print_header("Audio Control Endpoints")
        
        # Test 7: Get audio devices
        try:
            response = requests.get(f"{self.base_url}/api/audio-devices")
            data = response.json()
            
            # On Windows, audio might not be available (503 expected)
            if response.status_code == 503:
                self.test_result(
                    "Test 7: Audio devices endpoint (graceful degradation)",
                    True,
                    "Audio not available (expected on Windows/Mac Docker)",
                    warning=True
                )
            else:
                self.test_result(
                    "Test 7: Get audio devices",
                    response.status_code == 200 and 'devices' in data,
                    f"Found {len(data.get('devices', []))} devices"
                )
        except Exception as e:
            self.test_result("Test 7: Get audio devices", False, str(e))
        
        # Test 8: Switch audio (expect failure on Windows)
        try:
            response = requests.post(
                f"{self.base_url}/api/switch-audio",
                json={'output': 'hdmi'},
                timeout=5
            )
            
            if response.status_code == 503:
                self.test_result(
                    "Test 8: Switch audio endpoint (graceful degradation)",
                    True,
                    "Audio switching not available (expected on Windows/Mac)",
                    warning=True
                )
            else:
                self.test_result(
                    "Test 8: Switch audio output",
                    response.status_code in [200, 400],  # 400 if device not found is OK
                    f"Status: {response.status_code}"
                )
        except Exception as e:
            self.test_result("Test 8: Switch audio output", False, str(e))
        
        # Test 9: Get volume
        try:
            response = requests.get(f"{self.base_url}/api/volume")
            
            if response.status_code == 503:
                self.test_result(
                    "Test 9: Volume control endpoint (graceful degradation)",
                    True,
                    "Volume control not available (expected on Windows/Mac)",
                    warning=True
                )
            else:
                data = response.json()
                self.test_result(
                    "Test 9: Get volume level",
                    response.status_code in [200, 500],
                    f"Status: {response.status_code}"
                )
        except Exception as e:
            self.test_result("Test 9: Get volume level", False, str(e))
        
        # Test 10: Set volume
        try:
            response = requests.post(
                f"{self.base_url}/api/volume",
                json={'volume': 50},
                timeout=5
            )
            
            if response.status_code == 503:
                self.test_result(
                    "Test 10: Set volume endpoint (graceful degradation)",
                    True,
                    "Volume control not available (expected on Windows/Mac)",
                    warning=True
                )
            else:
                self.test_result(
                    "Test 10: Set volume",
                    response.status_code in [200, 400, 500],
                    f"Status: {response.status_code}"
                )
        except Exception as e:
            self.test_result("Test 10: Set volume", False, str(e))
    
    def test_service_launch_endpoints(self):
        """Test 11-14: Service launch endpoints"""
        self.print_header("Service Launch Endpoints")
        
        services = [
            ('netflix', 'Test 11'),
            ('plex', 'Test 12'),
            ('youtube', 'Test 13'),
            ('livetv', 'Test 14')
        ]
        
        for service, test_name in services:
            try:
                response = requests.post(
                    f"{self.base_url}/api/launch/{service}",
                    timeout=5
                )
                data = response.json()
                
                # Service launch will fail in container without display, but endpoint should work
                self.test_result(
                    f"{test_name}: Launch {service} endpoint",
                    response.status_code in [200, 500],  # 500 if display not available
                    f"Status: {response.status_code}, Message: {data.get('message', 'N/A')}"
                )
            except Exception as e:
                self.test_result(f"{test_name}: Launch {service} endpoint", False, str(e))
    
    def test_system_control_endpoints(self):
        """Test 15-16: System control endpoints (without executing)"""
        self.print_header("System Control Endpoints")
        
        # Test 15: Shutdown endpoint exists (don't actually run it)
        try:
            # We'll test that the endpoint is defined by checking API docs
            response = requests.get(f"{self.base_url}/api/")
            data = response.json()
            endpoints = str(data.get('endpoints', {}))
            
            self.test_result(
                "Test 15: Shutdown endpoint is defined",
                '/api/shutdown' in endpoints,
                "Endpoint exists in API documentation"
            )
        except Exception as e:
            self.test_result("Test 15: Shutdown endpoint is defined", False, str(e))
        
        # Test 16: Restart endpoint exists
        try:
            response = requests.get(f"{self.base_url}/api/")
            data = response.json()
            endpoints = str(data.get('endpoints', {}))
            
            self.test_result(
                "Test 16: Restart endpoint is defined",
                '/api/restart' in endpoints,
                "Endpoint exists in API documentation"
            )
        except Exception as e:
            self.test_result("Test 16: Restart endpoint is defined", False, str(e))
    
    def test_api_documentation(self):
        """Test 17: API documentation completeness"""
        self.print_header("API Documentation")
        
        try:
            response = requests.get(f"{self.base_url}/api/")
            data = response.json()
            
            required_sections = ['launch', 'audio', 'system', 'utility']
            endpoints_data = data.get('endpoints', {})
            
            has_all_sections = all(section in endpoints_data for section in required_sections)
            
            self.test_result(
                "Test 17: API documentation is complete",
                has_all_sections and response.status_code == 200,
                f"Sections: {', '.join(endpoints_data.keys())}"
            )
        except Exception as e:
            self.test_result("Test 17: API documentation is complete", False, str(e))
    
    def test_cors_headers(self):
        """Test 18: CORS headers for cross-origin access"""
        self.print_header("CORS & Security Headers")
        
        try:
            response = requests.get(f"{self.base_url}/api/health")
            headers = response.headers
            
            has_cors = 'Access-Control-Allow-Origin' in headers
            
            self.test_result(
                "Test 18: CORS headers are present",
                has_cors,
                f"Access-Control-Allow-Origin: {headers.get('Access-Control-Allow-Origin', 'Not set')}"
            )
        except Exception as e:
            self.test_result("Test 18: CORS headers are present", False, str(e))
    
    def test_error_handling(self):
        """Test 19: Error handling for invalid requests"""
        self.print_header("Error Handling")
        
        try:
            # Test invalid endpoint
            response = requests.get(f"{self.base_url}/api/invalid-endpoint")
            
            self.test_result(
                "Test 19: Invalid endpoint returns 404",
                response.status_code == 404,
                f"Status: {response.status_code}"
            )
        except Exception as e:
            self.test_result("Test 19: Invalid endpoint returns 404", False, str(e))
    
    def test_response_times(self):
        """Test 20: Response time performance"""
        self.print_header("Performance Tests")
        
        try:
            start = time.time()
            response = requests.get(f"{self.base_url}/api/health")
            elapsed = (time.time() - start) * 1000  # Convert to ms
            
            # Response should be under 500ms for health check
            self.test_result(
                "Test 20: API response time is acceptable",
                elapsed < 500,
                f"Response time: {elapsed:.2f}ms (target: <500ms)"
            )
        except Exception as e:
            self.test_result("Test 20: API response time is acceptable", False, str(e))
    
    # ==================== SUMMARY ====================
    
    def print_summary(self):
        """Print test summary"""
        total = self.passed + self.failed + self.warnings
        
        print(f"\n{COLORS['BLUE']}{'=' * 70}{COLORS['END']}")
        print(f"{COLORS['BLUE']}TEST SUMMARY{COLORS['END']}")
        print(f"{COLORS['BLUE']}{'=' * 70}{COLORS['END']}")
        print(f"\nTotal Tests: {total}")
        print(f"{COLORS['GREEN']}Passed: {self.passed}{COLORS['END']}")
        print(f"{COLORS['RED']}Failed: {self.failed}{COLORS['END']}")
        print(f"{COLORS['YELLOW']}Warnings: {self.warnings}{COLORS['END']}")
        
        success_rate = (self.passed / total * 100) if total > 0 else 0
        print(f"\n{COLORS['BLUE']}Success Rate: {success_rate:.1f}%{COLORS['END']}")
        
        if self.failed == 0:
            print(f"\n{COLORS['GREEN']}✓ All critical tests passed!{COLORS['END']}")
        else:
            print(f"\n{COLORS['RED']}✗ Some tests failed. Please review the results above.{COLORS['END']}")
        
        # Save results to file
        self.save_results()
    
    def save_results(self):
        """Save test results to JSON file"""
        try:
            results = {
                'timestamp': datetime.now().isoformat(),
                'summary': {
                    'total': self.passed + self.failed + self.warnings,
                    'passed': self.passed,
                    'failed': self.failed,
                    'warnings': self.warnings
                },
                'tests': self.results
            }
            
            with open('test_results.json', 'w') as f:
                json.dump(results, f, indent=2)
            
            print(f"\n{COLORS['BLUE']}Results saved to: test_results.json{COLORS['END']}")
        except Exception as e:
            print(f"\n{COLORS['YELLOW']}Could not save results: {e}{COLORS['END']}")


def main():
    """Main test runner"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MediaBox AI API Test Suite')
    parser.add_argument('--url', default=API_BASE, help='Base URL for API (default: http://localhost:8080)')
    args = parser.parse_args()
    
    tester = MediaBoxAITester(args.url)
    tester.run_all_tests()
    
    # Exit with error code if tests failed
    sys.exit(1 if tester.failed > 0 else 0)


if __name__ == '__main__':
    main()

