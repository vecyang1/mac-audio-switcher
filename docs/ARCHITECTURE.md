# AudioSwitch Pro - Technical Architecture

## Overview

AudioSwitch Pro is built as a native macOS application using Swift and SwiftUI, designed for optimal performance and seamless integration with the macOS ecosystem.

## Architecture Principles

1. **MVVM Pattern**: Clear separation between Views, ViewModels, and Models
2. **Protocol-Oriented**: Heavy use of protocols for testability and flexibility
3. **Reactive Programming**: Combine framework for data flow
4. **Dependency Injection**: For better testability and modularity

## Core Components

### 1. Audio Device Manager
```swift
class AudioDeviceManager: ObservableObject {
    // Manages Core Audio integration
    // Monitors device changes
    // Handles audio route switching
}
```

**Responsibilities:**
- Enumerate available audio devices
- Monitor device connection/disconnection
- Execute audio route changes
- Maintain device state

### 2. Shortcut Manager
```swift
class ShortcutManager: ObservableObject {
    // Global hotkey registration
    // Shortcut conflict detection
    // User preference storage
}
```

**Responsibilities:**
- Register/unregister global hotkeys
- Detect conflicts with system shortcuts
- Persist shortcut configurations
- Handle shortcut triggers

### 3. Bluetooth Manager
```swift
class BluetoothManager: NSObject, CBCentralManagerDelegate {
    // Core Bluetooth integration
    // Device discovery and monitoring
}
```

**Responsibilities:**
- Scan for Bluetooth audio devices
- Monitor connection status
- Report battery levels
- Handle pairing requests

## Data Flow

```
User Input → View → ViewModel → Service → Core Framework
                         ↓
                    Model Update
                         ↓
                 View Update ← ViewModel
```

## Key Technologies

### Audio Handling
- **AVAudioEngine**: For audio session management
- **Core Audio**: Low-level audio device control
- **AudioToolbox**: Audio route manipulation

### UI Framework
- **SwiftUI**: Entire user interface
- **Combine**: Reactive data binding
- **AppKit**: System integration where needed

### System Integration
- **ServiceManagement**: Auto-start functionality
- **UserNotifications**: Optional notifications
- **Security**: Keychain for sensitive data

## Security Model

### Sandboxing
- App is sandboxed for Mac App Store
- Entitlements for audio and Bluetooth access
- No network access by default

### Permissions
1. **com.apple.security.device.audio-input**: Audio device access
2. **com.apple.security.device.bluetooth**: Bluetooth access
3. **com.apple.security.automation**: For global shortcuts

## Performance Optimization

### Memory Management
- Lazy loading of device icons
- Efficient caching of device states
- Proper cleanup of audio sessions

### CPU Optimization
- Throttled device scanning
- Efficient Core Audio callbacks
- Background thread processing

## Testing Strategy

### Unit Tests
- Service layer logic
- ViewModel behavior
- Model validation

### Integration Tests
- Audio switching functionality
- Shortcut registration
- Device detection

### UI Tests
- User flows
- Accessibility
- Keyboard navigation

## Build & Distribution

### Build Configuration
- **Debug**: Full logging, no optimization
- **Release**: Optimized, minimal logging
- **AppStore**: Sandboxed, no private APIs

### Code Signing
- Developer ID for direct distribution
- App Store certificates for MAS
- Notarization for Gatekeeper

## Future Considerations

### Extensibility
- Plugin architecture for custom actions
- AppleScript support
- Shortcuts app integration

### Cross-Platform
- Catalyst for iPad support
- Shared codebase considerations