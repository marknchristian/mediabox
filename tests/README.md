# MediaBox AI Test Suite

Comprehensive testing suite for MediaBox AI Dashboard with automated and manual tests.

---

## 📋 Test Overview

### Automated Tests (20 tests)
- **API Tests**: Automated Python script testing all API endpoints
- **Server Tests**: Shell script testing container internals

### Manual Tests (60+ checks)
- **Web Frontend**: Complete manual testing checklist
- **Cross-browser**: Testing in multiple browsers
- **Mobile**: Testing on mobile devices

---

## 🚀 Quick Start

### 1. Run Automated API Tests

```powershell
# On Windows
cd mediabox-dev
docker exec mediabox-controller python3 /app/tests/test_api.py

# Or from host (requires Python 3 and requests package)
pip install requests
python tests/test_api.py
```

### 2. Run Server-Side Tests

```bash
# On Linux/Mac
cd mediabox-dev
bash tests/server_tests.sh

# On Windows (Git Bash or WSL)
bash tests/server_tests.sh
```

### 3. Manual Testing

Open `tests/manual_tests.md` and follow the checklist.

---

## 📦 Test Files

| File | Description | Type |
|------|-------------|------|
| `test_api.py` | Automated API endpoint tests | Python Script |
| `server_tests.sh` | Server-side component tests | Bash Script |
| `manual_tests.md` | Web frontend test checklist | Documentation |
| `README.md` | This file | Documentation |

---

## 🧪 Test Categories

### API Tests (test_api.py)

**Test 1-2: Connectivity**
- Server reachability
- Dashboard accessibility

**Test 3-4: Health & Status**
- Health endpoint
- Status endpoint

**Test 5-6: Dashboard Serving**
- HTML content
- API documentation

**Test 7-10: Audio Endpoints**
- Get audio devices
- Switch audio
- Get volume
- Set volume

**Test 11-14: Service Launch**
- Netflix, Plex, YouTube, Live TV

**Test 15-16: System Control**
- Shutdown endpoint
- Restart endpoint

**Test 17: API Documentation**
- Documentation completeness

**Test 18: CORS Headers**
- Cross-origin access

**Test 19: Error Handling**
- Invalid endpoints

**Test 20: Performance**
- Response times

### Server Tests (server_tests.sh)

**Test 1-2: Container Health**
- Container running
- Supervisor process

**Test 3-6: Service Status**
- PulseAudio, Xvfb, Flask, Home Assistant

**Test 7-8: Network & Ports**
- Port 8080, 8123 listening

**Test 9-11: File System**
- Files exist and executable

**Test 12-14: Python Environment**
- Packages installed

**Test 15-16: Application Logs**
- Error checking

**Test 17-18: Processes**
- Process verification

**Test 19-20: Resources**
- CPU and memory usage

---

## 📊 Expected Results

### On Windows/Mac Docker

**Pass (with warnings):**
- ✅ All API endpoints respond
- ✅ Dashboard loads
- ⚠️ Audio endpoints return 503 (expected)
- ✅ Service launch endpoints work
- ✅ All server components running

**Success Criteria:** 15+ tests pass, 5 warnings

### On Linux with Audio

**Full Pass:**
- ✅ All API endpoints work fully
- ✅ Audio switching works
- ✅ Volume control works
- ✅ All services operational

**Success Criteria:** 18+ tests pass

---

## 🔧 Running Tests

### Prerequisites

**For API Tests:**
```bash
pip install requests
```

**For Server Tests:**
- Bash shell (Git Bash on Windows)
- Docker running
- MediaBox AI container running

### Running Individual Tests

```bash
# Just connectivity tests
python tests/test_api.py --help

# Test against remote server
python tests/test_api.py --url http://192.168.0.232:8080

# Server tests only for specific components
docker exec mediabox-controller supervisorctl status
```

---

## 📈 Test Results

### Viewing Results

**API Tests:**
- Console output with colored results
- `test_results.json` file created
- Success/failure exit codes

**Server Tests:**
- Console output with colored results
- Success/failure exit codes

**Manual Tests:**
- Fill out checklist in `manual_tests.md`
- Record pass/fail for each test

### Result Files

```
tests/
├── test_results.json      # API test results (auto-generated)
├── manual_results.txt     # Your manual test results
└── screenshots/           # Test screenshots (optional)
```

---

## 🐛 Troubleshooting Tests

### API Tests Fail to Connect

```bash
# Check if container is running
docker-compose ps

# Check if Flask is running
docker logs mediabox-controller | grep Flask

# Test connectivity
curl http://localhost:8080/api/health
```

### Server Tests Can't Access Container

```bash
# Verify container name
docker ps

# Check Docker is running
docker --version

# Try manual command
docker exec mediabox-controller echo "test"
```

### Tests Run But Show Warnings

**This is normal on Windows/Mac:**
- Audio tests will warn (audio not available)
- Some service launches may fail (no display)
- These are expected behaviors

---

## 📝 Creating New Tests

### Adding API Tests

Edit `test_api.py`:

```python
def test_new_feature(self):
    """Test new feature"""
    self.print_header("New Feature Tests")
    
    try:
        response = requests.get(f"{self.base_url}/api/new-endpoint")
        self.test_result(
            "Test X: New feature works",
            response.status_code == 200,
            f"Status: {response.status_code}"
        )
    except Exception as e:
        self.test_result("Test X: New feature works", False, str(e))
```

### Adding Server Tests

Edit `server_tests.sh`:

```bash
# Test X: New component
if docker exec "$CONTAINER_NAME" test -f /path/to/file; then
    test_result "Test X: New component exists" "pass"
else
    test_result "Test X: New component exists" "fail"
fi
```

### Adding Manual Tests

Edit `manual_tests.md`:

```markdown
#### ✅ Test X.Y: New Feature
- [ ] Step 1
- [ ] Step 2
- [ ] Verify result

**Expected**: Description of expected behavior
```

---

## 🎯 Test Coverage

### Current Coverage

- ✅ **API Endpoints**: 100% coverage
- ✅ **Server Components**: 100% coverage
- ✅ **Web Frontend**: Comprehensive checklist
- ✅ **Error Handling**: Basic coverage
- ✅ **Performance**: Basic monitoring

### Areas for Expansion

- ⬜ Integration tests (end-to-end workflows)
- ⬜ Load testing (concurrent users)
- ⬜ Security testing (penetration tests)
- ⬜ Accessibility testing (WCAG compliance)
- ⬜ Browser automation (Selenium/Playwright)

---

## 📚 Best Practices

1. **Run tests after every change**
2. **Test on target platform** (Linux for production)
3. **Document unexpected results**
4. **Keep manual test checklist updated**
5. **Save test results** for tracking
6. **Test on multiple browsers**
7. **Test on actual mobile devices**

---

## 🆘 Getting Help

If tests fail unexpectedly:

1. Check container logs: `docker-compose logs`
2. Verify services: `docker exec mediabox-controller supervisorctl status`
3. Test API manually: `curl http://localhost:8080/api/health`
4. Review test output carefully
5. Check for Docker/network issues

---

## 📞 Support

For issues with tests:
- Check `DOCKER_README.md` for troubleshooting
- Review `BUILD_SUCCESS.md` for deployment info
- Verify container is healthy: `docker-compose ps`

