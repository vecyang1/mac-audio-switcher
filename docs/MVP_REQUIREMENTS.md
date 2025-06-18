# AudioSwitch Pro - MVP Requirements

## MVP Goal
Create a beautiful, functional macOS app that allows users to switch audio devices instantly using keyboard shortcuts.

## Core Features Only (v1.0)

### 1. Simple Main Window
- **Clean device list** showing all available audio outputs
- **One-click switching** by clicking any device
- **Visual indicator** for currently active device
- **Modern SwiftUI design** with native macOS styling

### 2. Basic Keyboard Shortcuts
- **Single global shortcut** to toggle between last 2 devices
- **Simple shortcut editor** - click button, press keys, done
- **No complex configurations** in v1.0

### 3. Essential Settings
- **Auto-start option** (checkbox)
- **Shortcut configuration** (one field)
- **About section** with version info

### 4. Minimal Device Info
- Device name
- Device type icon (speaker/headphone)
- Active status (checkmark or highlight)
- Connection type (Bluetooth/Wired/Internal)

## NOT in MVP (Save for v2.0)
- ❌ Multiple shortcuts for specific devices
- ❌ Device renaming
- ❌ Favorites system
- ❌ Battery monitoring
- ❌ Themes/appearance options
- ❌ Import/export settings
- ❌ Sound feedback
- ❌ Notifications
- ❌ Device profiles
- ❌ Search functionality
- ❌ Grid view option

## Technical Simplifications

### UI Components (3 screens only)
1. **Main Window**: Device list
2. **Settings Window**: 2 options (auto-start, shortcut)
3. **About Window**: Version and credits

### Architecture
- Single AudioDeviceManager service
- One ViewModel for the main window
- Simple UserDefaults for preferences
- No complex state management

### Permissions
- Only request Accessibility permission (for shortcuts)
- Skip Bluetooth permission scanning (use Core Audio only)

## Design Principles
1. **Beautiful**: Modern, clean SwiftUI interface
2. **Fast**: Instant switching, no delays
3. **Simple**: No learning curve
4. **Reliable**: Just works

## Success Criteria
- User can see all audio devices
- User can switch with one click
- User can set one keyboard shortcut
- App can auto-start (optional)
- Switching takes <50ms

## Development Timeline
- Week 1: Core audio switching + basic UI
- Week 2: Keyboard shortcut implementation
- Week 3: Polish UI + testing
- Week 4: Release preparation

## UI Mockup Structure
```
┌─────────────────────────────────┐
│ AudioSwitch Pro                 │
├─────────────────────────────────┤
│                                 │
│ 🔊 MacBook Pro Speakers    ✓   │
│ ─────────────────────────────   │
│                                 │
│ 🎧 AirPods Pro                  │
│ ─────────────────────────────   │
│                                 │
│ 🔊 External Display             │
│ ─────────────────────────────   │
│                                 │
│ [Settings] [Shortcut: ⌘⌥A]     │
└─────────────────────────────────┘
```