# Silent Mode Feature Documentation

## Overview
The Silent Mode feature allows users to disable AudioSwitch Pro shortcuts when certain applications are active. This is useful when working in apps like Notion, Final Cut Pro, or other applications where AudioSwitch Pro shortcuts might interfere with the app's own keyboard shortcuts.

## Implementation Status

### ✅ Completed Components
1. **Data Model** (`SilentModeApp.swift`)
   - Stores app bundle ID, name, path, and enabled state
   - Supports persistence via UserDefaults
   - Extracts app info from bundle URLs

2. **Service Layer** (`SilentModeManager.swift`)
   - Monitors currently active application
   - Maintains list of apps in silent mode
   - Publishes `isSilentModeActive` state
   - Handles app selection via NSOpenPanel

3. **UI Component** (`SilentModeView.swift`)
   - Displays list of apps with toggle switches
   - Add/remove apps functionality
   - Visual indicator when silent mode is active
   - Matches Manico's design pattern

4. **Integration** (Partial)
   - ShortcutManager checks for silent mode (currently commented out)
   - SettingsView prepared for tabs (needs full implementation)

### ⚠️ Pending Tasks
1. **Add files to Xcode project**
   - SilentModeApp.swift → Models group
   - SilentModeManager.swift → Services group
   - SilentModeView.swift → Views group

2. **Enable the integration**
   - Uncomment silent mode check in ShortcutManager.swift
   - Add Silent Mode tab to SettingsView

## How to Complete Setup

### Step 1: Add Files to Xcode
```bash
# Open Xcode
open /Users/vecsatfoxmailcom/Documents/A-coding/25.06.18\ Audio-switch/src/AudioSwitchPro.xcodeproj

# In Xcode:
1. Right-click Models folder → Add Files to "AudioSwitchPro"
2. Select SilentModeApp.swift
3. Repeat for Services/SilentModeManager.swift
4. Repeat for Views/SilentModeView.swift
```

### Step 2: Enable Silent Mode in Code
1. In `ShortcutManager.swift`, uncomment lines 122-125:
```swift
if SilentModeManager.shared.isSilentModeActive {
    print("🔇 Silent mode is active - ignoring shortcut")
    return
}
```

2. In `SettingsView.swift`, add Silent Mode tab integration

### Step 3: Build and Test
```bash
./scripts/build-and-run.sh
```

## Usage
1. Open Settings → Silent Mode tab
2. Click + to add applications
3. Toggle "Disable Shortcuts" for each app
4. When those apps are active, all AudioSwitch Pro shortcuts are disabled

## Technical Details
- Uses `NSWorkspace.didActivateApplicationNotification` for app monitoring
- Stores app list in UserDefaults with Codable support
- Real-time state updates via Combine publishers
- No performance impact when silent mode is not active

## Future Enhancements
- Option to disable only specific shortcuts per app
- Notification when entering/exiting silent mode
- Quick toggle in menu bar
- Import/export silent mode configurations