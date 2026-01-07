# Silent Mode Setup Instructions

## Overview
The Silent Mode feature has been implemented to disable AudioSwitch Pro shortcuts when certain apps are active (like Notion or Final Cut Pro).

## New Files Created
1. `src/AudioSwitchPro/Models/SilentModeApp.swift` - Data model for silent mode apps
2. `src/AudioSwitchPro/Services/SilentModeManager.swift` - Service to manage silent mode and monitor active apps
3. `src/AudioSwitchPro/Views/SilentModeView.swift` - UI component for the Silent Mode settings tab

## Modified Files
1. `src/AudioSwitchPro/Utilities/ShortcutManager.swift` - Added silent mode check in handleHotKeyEvent
2. `src/AudioSwitchPro/Views/SettingsView.swift` - Added tabs including Silent Mode tab

## To Complete Setup in Xcode

### 1. Add New Files to Project
1. Open `AudioSwitchPro.xcodeproj` in Xcode
2. Right-click on the appropriate group and select "Add Files to AudioSwitchPro..."
3. Add these files:
   - Navigate to `Models` folder and add `SilentModeApp.swift`
   - Navigate to `Services` folder and add `SilentModeManager.swift`
   - Navigate to `Views` folder and add `SilentModeView.swift`
4. Ensure "Copy items if needed" is unchecked (files are already in place)
5. Ensure the target "AudioSwitchPro" is checked

### 2. Build and Test
1. Build the project (⌘B)
2. Run the app
3. Open Settings and navigate to the new "Silent Mode" tab
4. Add apps like Notion or Final Cut Pro
5. Test that shortcuts are disabled when those apps are active

## How It Works

### Silent Mode Manager
- Monitors the currently active application using `NSWorkspace`
- Maintains a list of apps where shortcuts should be disabled
- Provides a published property `isSilentModeActive` that other components can observe

### Shortcut Manager Integration
- Before processing any hotkey, checks if Silent Mode is active
- If active, ignores the shortcut and logs a message

### User Interface
- New tab in Settings showing list of apps
- Users can add/remove apps using the + and - buttons
- Toggle switches to enable/disable Silent Mode for each app
- Visual indicator when Silent Mode is currently active

## Testing
Run the included test script to verify core functionality:
```bash
swift test-silent-mode.swift
```

## Future Enhancements
- Add notification when Silent Mode activates/deactivates
- Option to show a temporary overlay when shortcuts are blocked
- Import/export Silent Mode app lists
- Automatic suggestions for commonly used creative apps