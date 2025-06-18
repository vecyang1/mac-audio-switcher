# AudioSwitch Pro - MVP Architecture (Simplified)

## Overview
Minimal architecture focused on delivering core functionality with clean code.

## Project Structure (MVP Only)
```
AudioSwitchPro/
├── App/
│   ├── AudioSwitchProApp.swift      // App entry point
│   └── AppDelegate.swift            // Handle auto-start
├── Models/
│   └── AudioDevice.swift            // Simple device model
├── Views/
│   ├── ContentView.swift            // Main window
│   ├── DeviceRowView.swift          // Device list item
│   └── SettingsView.swift           // Settings sheet
├── Services/
│   └── AudioManager.swift           // Core Audio wrapper
├── Utilities/
│   └── ShortcutManager.swift        // Keyboard shortcuts
└── Resources/
    └── Assets.xcassets              // Icons and colors
```

## Core Components (Only 5 Files)

### 1. AudioDevice Model
```swift
struct AudioDevice: Identifiable {
    let id: String              // Device UID
    let name: String            // Display name
    let isOutput: Bool          // Output device flag
    let transportType: String   // "Bluetooth", "USB", "Internal"
    var isActive: Bool          // Currently selected
}
```

### 2. AudioManager Service
```swift
class AudioManager: ObservableObject {
    @Published var devices: [AudioDevice] = []
    @Published var activeDeviceID: String?
    
    func refreshDevices()
    func switchToDevice(_ deviceID: String)
    func toggleBetweenLastTwo()
}
```

### 3. Main ContentView
```swift
struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @State private var showSettings = false
    
    var body: some View {
        // Simple list of devices
        // Click to switch
        // Settings button
    }
}
```

### 4. ShortcutManager
```swift
class ShortcutManager {
    static let shared = ShortcutManager()
    
    func registerShortcut(_ keyCombo: String, action: @escaping () -> Void)
    func unregisterShortcut()
}
```

### 5. Settings Storage
```swift
// Simple UserDefaults
extension UserDefaults {
    var autoStartEnabled: Bool
    var globalShortcut: String?
}
```

## Data Flow (Simplified)
```
User clicks device → AudioManager.switchToDevice() → Core Audio API → Update UI
User presses shortcut → ShortcutManager → AudioManager.toggleBetweenLastTwo() → Update UI
```

## Core Audio Integration (Minimal)
```swift
// Only what we need:
- AudioObjectGetPropertyData() // Get device list
- AudioObjectSetPropertyData() // Set default device
- AudioObjectAddPropertyListener() // Monitor changes
```

## No Dependencies
- Pure Swift/SwiftUI
- No third-party packages
- No complex state management
- No networking

## Build Settings
- **Deployment Target**: macOS 12.0
- **Swift Version**: 5.9
- **Architecture**: Universal (Apple Silicon + Intel)
- **Optimization**: Size-optimized

## Security Entitlements (Minimal)
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
```

## Testing Strategy (Simple)
- Manual testing for MVP
- Basic unit tests for AudioManager
- No complex test setup

## Performance Goals
- App launch: <500ms
- Device list refresh: <50ms
- Audio switch: <50ms
- Memory usage: <30MB

## MVP Deliverables
1. Single .app bundle
2. Simple DMG installer
3. Basic README
4. GitHub release

## What We're NOT Building
- No menu bar app
- No complex preferences
- No analytics
- No update checker
- No error reporting
- No localization
- No help system

## Success = Simple + Beautiful + Works