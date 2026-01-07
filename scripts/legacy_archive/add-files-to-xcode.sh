#!/bin/bash

echo "🔧 Adding Silent Mode files to Xcode project"
echo "==========================================="
echo ""
echo "Please follow these steps in Xcode:"
echo ""
echo "1. In the Navigator (left panel), right-click on the 'Models' folder"
echo "2. Select 'Add Files to \"AudioSwitchPro\"...'"
echo "3. Navigate to src/AudioSwitchPro/Models/"
echo "4. Select 'SilentModeApp.swift'"
echo "5. Make sure 'Copy items if needed' is UNCHECKED"
echo "6. Make sure 'AudioSwitchPro' target is CHECKED"
echo "7. Click 'Add'"
echo ""
echo "Repeat the same process for:"
echo "- Services/SilentModeManager.swift"
echo "- Views/SilentModeView.swift"
echo ""
echo "Opening Xcode now..."

open /Users/vecsatfoxmailcom/Documents/A-coding/25.06.18\ Audio-switch/src/AudioSwitchPro.xcodeproj

echo ""
echo "After adding the files, run: ./scripts/build-and-run.sh"