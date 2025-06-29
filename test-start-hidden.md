# Testing the "Start Hidden on Login" Feature

## Test Scenarios

### 1. Normal Launch (Feature Disabled)
- **Setup**: Ensure "Start hidden on login" is disabled in Settings
- **Test**: Launch the app normally (double-click)
- **Expected**: Main window should appear immediately

### 2. Normal Launch (Feature Enabled)
- **Setup**: Enable "Start hidden on login" in Settings
- **Test**: Launch the app normally (double-click)
- **Expected**: Main window should appear (feature only affects login launch)

### 3. Simulated Login Launch (Feature Disabled)
- **Setup**: Ensure "Start hidden on login" is disabled
- **Test**: Launch app via Terminal with: `open -a AudioSwitchPro`
- **Expected**: Main window should appear

### 4. Simulated Login Launch (Feature Enabled) ✨
- **Setup**: 
  1. Enable "Launch at login" in Settings
  2. Enable "Start hidden on login" in Settings
  3. Quit the app completely
- **Test**: Launch app via Terminal to simulate login
- **Expected**: 
  - App should start in background
  - NO main window should appear
  - Menu bar icon should appear (if enabled)
  - Keyboard shortcuts should work

### 5. Menu Bar Access When Hidden
- **Setup**: App launched with "start hidden" active
- **Test**: Click menu bar icon → "Show Main Panel"
- **Expected**: Main window should appear normally

### 6. Keyboard Shortcut Access When Hidden
- **Setup**: App launched with "start hidden" active
- **Test**: Use global panel toggle shortcut
- **Expected**: Main window should appear/hide as normal

## Console Monitoring

Run this in Terminal to see debug output:
```bash
log stream --predicate 'process == "AudioSwitchPro"' --level debug
```

Look for these messages:
- `🔍 App launched normally (not at login)` - Normal launch detected
- `🔍 System uptime is X seconds - likely launched at login` - Login launch detected
- `🫥 App launched at login with 'start hidden' enabled - skipping main window` - Feature working

## Manual Testing Steps

1. **Configure Settings**:
   - Open AudioSwitchPro
   - Go to Settings (⌘,)
   - Enable "Launch at login"
   - Enable "Start hidden on login" (should be indented under first option)
   - Close Settings

2. **Test Immediate Behavior**:
   - Quit app completely (⌘Q)
   - Relaunch normally
   - Verify window DOES appear (not a login launch)

3. **Test Login Simulation**:
   - Quit app completely
   - Wait a few seconds
   - Launch via Terminal: `open -a AudioSwitchPro`
   - Within first 60 seconds of system boot, it should start hidden

4. **Test Real Login** (Optional):
   - Enable both settings
   - Log out of macOS
   - Log back in
   - App should start without showing window

## Verification Checklist

- [ ] Setting appears in General section under "Launch at login"
- [ ] Setting is disabled when "Launch at login" is off
- [ ] Setting is indented to show relationship
- [ ] Help tooltip appears on hover
- [ ] Normal launches always show window
- [ ] Login launches respect the setting
- [ ] App remains fully functional when started hidden
- [ ] Can access app via menu bar or keyboard shortcuts