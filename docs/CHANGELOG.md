# AudioSwitch Pro Changelog

## Version 1.1.0 (Unreleased)

### New Features
- **Auto-Update System**: Check for updates from your WordPress site
  - Automatic update checks (configurable)
  - Manual update check in Settings
  - Update notifications with release notes
  - Redirects to purchase page for paid updates

- **Virtual Device Safety**
  - Virtual devices (Loopback Audio, etc.) hidden by default
  - Warning dialog on first attempt to use virtual devices
  - Settings option to enable virtual devices
  - Automatic recovery to built-in devices after crash
  - Virtual Devices section moved after Hidden Devices to discourage use

### Improvements
- **Menu Bar Icon**: Changed to more distinctive `speaker.circle.fill` icon
- **Crash Recovery**: Enhanced crash detection and recovery system
  - Detects crashes from virtual devices
  - Automatically resets to MacBook speakers/microphone
  - Shows notification explaining the recovery

### Bug Fixes
- Fixed race condition in AudioManager causing crashes with virtual devices
- Fixed crash recovery timing - now runs before AudioManager initializes
- Improved virtual device property handling to be more lenient
- Fixed async closure memory management with [weak self]

### Technical Changes
- Added `UpdateService.swift` for version checking
- Added `UpdateNotificationView.swift` for update UI
- Modified `AudioSwitchProApp.swift` for early crash recovery
- Enhanced `AudioManager.swift` with safer device handling
- Updated `SettingsView.swift` with Updates section
- Updated `ContentView.swift` with virtual device warnings

### Files Added
- `src/AudioSwitchPro/Services/UpdateService.swift`
- `src/AudioSwitchPro/Views/UpdateNotificationView.swift`
- `docs/UPDATE_SYSTEM.md`
- `docs/CHANGELOG.md`

### Known Issues
- UpdateService files need to be added to Xcode project
- Update endpoint URL needs to be configured