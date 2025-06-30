#!/bin/bash

# Test script for "Start hidden on login" feature

echo "=== Testing Start Hidden on Login Feature ==="
echo

# Kill any existing instance
echo "1. Killing any existing AudioSwitchPro instances..."
pkill -9 AudioSwitchPro 2>/dev/null || true
sleep 1

# Check current settings
echo "2. Checking current UserDefaults settings..."
echo "   autoStartEnabled: $(defaults read com.vecyang.AudioSwitchPro autoStartEnabled 2>/dev/null || echo 'not set')"
echo "   startHiddenOnLogin: $(defaults read com.vecyang.AudioSwitchPro startHiddenOnLogin 2>/dev/null || echo 'not set')"
echo

# Test 1: Normal launch (should show window)
echo "3. Test 1: Normal launch (window should appear)..."
open -a AudioSwitchPro
sleep 3

# Check if window is visible
echo "   Checking for visible windows..."
WINDOW_COUNT=$(osascript -e 'tell application "System Events" to tell process "AudioSwitchPro" to count windows' 2>/dev/null || echo "0")
echo "   Visible windows: $WINDOW_COUNT"

# Kill app
pkill -9 AudioSwitchPro 2>/dev/null || true
sleep 1

# Test 2: Enable settings and test
echo
echo "4. Test 2: Enabling 'start hidden' settings..."
defaults write com.vecyang.AudioSwitchPro autoStartEnabled -bool true
defaults write com.vecyang.AudioSwitchPro startHiddenOnLogin -bool true
echo "   Settings updated"

# Test 3: Simulate login launch (with low uptime check)
echo
echo "5. Test 3: Testing with uptime < 60 seconds simulation..."
echo "   Note: This will only hide window if system uptime < 60 seconds"
echo "   Current system uptime: $(uptime | awk '{print $3 " " $4}')"

# Launch app
open -a AudioSwitchPro
sleep 3

# Check window visibility again
WINDOW_COUNT=$(osascript -e 'tell application "System Events" to tell process "AudioSwitchPro" to count windows' 2>/dev/null || echo "0")
echo "   Visible windows after 'login' launch: $WINDOW_COUNT"

# Check if app is running
if pgrep -x "AudioSwitchPro" > /dev/null; then
    echo "   ✓ App is running"
else
    echo "   ✗ App is not running"
fi

# Check menu bar
echo
echo "6. Checking menu bar icon setting..."
echo "   showMenuBarIcon: $(defaults read com.vecyang.AudioSwitchPro showMenuBarIcon 2>/dev/null || echo 'not set')"

echo
echo "=== Test Summary ==="
echo "- The 'Start hidden on login' feature is configured"
echo "- It will only hide the window when:"
echo "  1. App is launched at system login (within 60 seconds of boot)"
echo "  2. Both 'Launch at login' and 'Start hidden on login' are enabled"
echo "- For real testing, enable both settings and restart your Mac"
echo
echo "To test manually:"
echo "1. Open AudioSwitchPro"
echo "2. Go to Settings (⌘,)"
echo "3. Enable 'Launch at login'"
echo "4. Enable 'Start hidden on login' (indented option)"
echo "5. Restart your Mac"
echo "6. After login, app should be running but window hidden"