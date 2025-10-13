# MediaBox AI Manual Test Checklist

Complete manual testing checklist for the MediaBox AI Dashboard web frontend.

---

## 🌐 Web Frontend Tests

### Test Suite 1: Dashboard Loading & Display

#### ✅ Test 1.1: Dashboard Loads Successfully
- [ ] Open http://localhost:8080 in browser
- [ ] Page loads without errors
- [ ] No JavaScript console errors (F12 → Console tab)
- [ ] All CSS styles are applied correctly

**Expected**: Beautiful glassmorphism dashboard with gradient background

#### ✅ Test 1.2: Responsive Design
- [ ] Open dashboard on desktop (full screen)
- [ ] Resize browser window to tablet size (~768px)
- [ ] Resize to mobile size (~375px)
- [ ] Test on actual mobile device if available

**Expected**: Layout adapts gracefully to different screen sizes

---

### Test Suite 2: Streaming Service Buttons

#### ✅ Test 2.1: Netflix Button
- [ ] Click Netflix button
- [ ] Status message appears: "Launching netflix..."
- [ ] Check browser console for API response
- [ ] Verify POST request to `/api/launch/netflix`

**Expected**: Status message changes to success or error

#### ✅ Test 2.2: Amazon Prime Button
- [ ] Click Amazon Prime button
- [ ] Status message appears
- [ ] Verify API call in network tab

**Expected**: Similar behavior to Netflix

#### ✅ Test 2.3: YouTube Button
- [ ] Click YouTube button
- [ ] Verify status message
- [ ] Check API response

**Expected**: Launch request sent successfully

#### ✅ Test 2.4: Plex Button
- [ ] Click Plex button
- [ ] Verify status message
- [ ] Check API response

**Expected**: Launch request sent successfully

---

### Test Suite 3: Additional Services

#### ✅ Test 3.1: Live TV Button
- [ ] Click Live TV button
- [ ] Status message appears
- [ ] Verify `/api/launch/livetv` call

**Expected**: IPTV launch attempted

#### ✅ Test 3.2: Smart Home Button
- [ ] Click Smart Home button
- [ ] Status message appears
- [ ] Should open Home Assistant

**Expected**: Launch request for Home Assistant

---

### Test Suite 4: Audio Controls

#### ✅ Test 4.1: Refresh Audio Devices
- [ ] Click "🔄 Refresh Audio" button
- [ ] Status message appears
- [ ] Check for API call to `/api/audio-devices`

**Expected**: On Windows: Message about audio not available
**Expected**: On Linux: List of audio devices appears

#### ✅ Test 4.2: HDMI Audio Button
- [ ] Click "HDMI" audio button
- [ ] Status message appears
- [ ] Button highlights if successful

**Expected**: On Windows: Error message (audio not available)
**Expected**: On Linux: Audio switches to HDMI

#### ✅ Test 4.3: SPDIF Audio Button
- [ ] Click "SPDIF (Optical/Coax)" button
- [ ] Status message appears

**Expected**: Similar to HDMI test

#### ✅ Test 4.4: Analog Audio Button
- [ ] Click "Analog (3.5mm)" button
- [ ] Status message appears

**Expected**: Similar to HDMI test

---

### Test Suite 5: Volume Control

#### ✅ Test 5.1: Volume Slider
- [ ] Move volume slider from 50% to 75%
- [ ] Volume percentage updates in real-time
- [ ] Status message appears after moving
- [ ] Verify API call (debounced, ~300ms delay)

**Expected**: Volume value updates, API called with delay

#### ✅ Test 5.2: Volume Slider Range
- [ ] Move slider to 0%
- [ ] Move slider to 100%
- [ ] Move to various positions

**Expected**: Slider responds smoothly, percentage updates

---

### Test Suite 6: System Controls

#### ✅ Test 6.1: Refresh Audio Button
- [ ] Click "🔄 Refresh Audio"
- [ ] Status message appears
- [ ] Audio devices list refreshes

**Expected**: Device list updates (or error on Windows)

#### ✅ Test 6.2: Shutdown Button (DON'T ACTUALLY CONFIRM)
- [ ] Click "🔌 Shutdown" button
- [ ] Confirmation dialog appears
- [ ] Click "Cancel"

**Expected**: Confirmation dialog shown, action cancelled

#### ✅ Test 6.3: Restart Button (DON'T ACTUALLY CONFIRM)
- [ ] Click "🔃 Restart" button
- [ ] Confirmation dialog appears
- [ ] Click "Cancel"

**Expected**: Confirmation dialog shown, action cancelled

---

### Test Suite 7: Status Messages

#### ✅ Test 7.1: Info Messages
- [ ] Trigger any action that shows info message
- [ ] Verify message has gray/dark background
- [ ] Message is readable

**Expected**: Gray background for info messages

#### ✅ Test 7.2: Success Messages
- [ ] Trigger successful action
- [ ] Verify message has green background
- [ ] Message auto-clears after 5 seconds

**Expected**: Green background, auto-clear

#### ✅ Test 7.3: Error Messages
- [ ] Trigger action that causes error (audio on Windows)
- [ ] Verify message has red background
- [ ] Message auto-clears after 5 seconds

**Expected**: Red background, auto-clear

---

### Test Suite 8: Interactive Behavior

#### ✅ Test 8.1: Button Hover Effects
- [ ] Hover over streaming service buttons
- [ ] Verify buttons lift up (translateY)
- [ ] Verify shadow appears
- [ ] Verify smooth transition

**Expected**: Smooth hover animation

#### ✅ Test 8.2: Button Click Feedback
- [ ] Click any button
- [ ] Verify visual feedback (slight movement)
- [ ] Button returns to normal state

**Expected**: Click animation plays

#### ✅ Test 8.3: Audio Button Active State
- [ ] Simulate active audio device
- [ ] Verify active button has green tint
- [ ] Verify other buttons are normal

**Expected**: Active button highlighted

---

### Test Suite 9: Network & API Integration

#### ✅ Test 9.1: API Connection
- [ ] Open browser DevTools (F12)
- [ ] Go to Network tab
- [ ] Click any service button
- [ ] Verify POST request appears
- [ ] Check response status (200 or appropriate error)

**Expected**: API calls visible in network tab

#### ✅ Test 9.2: API Response Handling
- [ ] Check response JSON format
- [ ] Verify `success` field exists
- [ ] Verify `message` field exists

**Expected**: Well-formed JSON responses

#### ✅ Test 9.3: Error Handling
- [ ] Stop the API server (docker-compose down)
- [ ] Try clicking buttons
- [ ] Verify error messages appear
- [ ] Restart server (docker-compose up -d)

**Expected**: Graceful error messages when API unavailable

---

### Test Suite 10: Cross-Browser Testing

#### ✅ Test 10.1: Chrome/Edge
- [ ] Test all features in Chrome or Edge
- [ ] Verify all buttons work
- [ ] Check console for errors

**Expected**: Full functionality

#### ✅ Test 10.2: Firefox
- [ ] Test in Firefox
- [ ] Verify UI renders correctly
- [ ] Test all interactive elements

**Expected**: Full functionality

#### ✅ Test 10.3: Safari (if on Mac)
- [ ] Test in Safari
- [ ] Verify glassmorphism effects work
- [ ] Test all features

**Expected**: Full functionality (some visual differences OK)

---

### Test Suite 11: Mobile Device Testing

#### ✅ Test 11.1: Mobile Browser
- [ ] Open http://192.168.0.232:8080 on mobile
- [ ] Test portrait orientation
- [ ] Test landscape orientation
- [ ] Test all buttons (touch targets)

**Expected**: Mobile-friendly, buttons easy to tap

#### ✅ Test 11.2: Tablet
- [ ] Test on tablet device
- [ ] Verify layout uses available space
- [ ] Test all features

**Expected**: Good use of tablet screen space

---

### Test Suite 12: Performance

#### ✅ Test 12.1: Page Load Time
- [ ] Clear browser cache
- [ ] Reload dashboard
- [ ] Time how long it takes to be interactive

**Expected**: <2 seconds for initial load

#### ✅ Test 12.2: Button Response Time
- [ ] Click multiple buttons rapidly
- [ ] Verify each action is registered
- [ ] Check if UI remains responsive

**Expected**: No lag or freezing

#### ✅ Test 12.3: Memory Usage
- [ ] Open browser task manager
- [ ] Monitor memory while using dashboard
- [ ] Leave dashboard open for 5+ minutes

**Expected**: No memory leaks, stable usage

---

## 📋 Test Result Template

```
Test Date: _______________
Tester: _______________
Browser: _______________
OS: _______________

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| 1.1  |  ☐   |  ☐   |       |
| 1.2  |  ☐   |  ☐   |       |
| 2.1  |  ☐   |  ☐   |       |
...
```

---

## 🔍 Known Issues / Expected Behaviors

### On Windows/Mac Docker:
- ❌ Audio device switching will fail (expected)
- ❌ Volume control will fail (expected)
- ✅ All other features should work

### In Docker Container:
- ❌ Service launching won't actually open apps (no display)
- ✅ API endpoints will respond correctly
- ✅ Dashboard will work perfectly

### On Linux with Audio:
- ✅ All features should work fully
- ✅ Audio switching should work
- ✅ Volume control should work

---

## 📊 Success Criteria

**Minimum for PASS:**
- ✅ Dashboard loads without errors
- ✅ All buttons are clickable
- ✅ Status messages appear
- ✅ API calls are made correctly
- ✅ No JavaScript console errors
- ✅ Responsive design works
- ✅ Works on mobile devices

**Full PASS:**
- ✅ All of the above
- ✅ Audio controls work (on Linux)
- ✅ All animations smooth
- ✅ No performance issues
- ✅ Works in all major browsers

