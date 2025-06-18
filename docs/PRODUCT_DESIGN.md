# AudioSwitch Pro - Product Design Document

## MVP Scope

**Important**: This document describes the full product vision. For the initial release, we are building a simplified MVP version focused on core functionality.

### MVP Implementation (v1.0)
- **Timeframe**: 4 weeks
- **Scope**: Core features only - see [MVP_REQUIREMENTS.md](./MVP_REQUIREMENTS.md)
- **Architecture**: Simplified design - see [MVP_ARCHITECTURE.md](./MVP_ARCHITECTURE.md)
- **Goal**: Beautiful, functional app that "just works"

### This Document
This document contains the complete product vision and will guide future development beyond the MVP. Features marked as "Post-MVP" will be implemented in v2.0 and beyond.

---

## Executive Summary

AudioSwitch Pro is a native macOS application with a modern, user-friendly interface that provides seamless audio output device switching through customizable keyboard shortcuts. The app features a full UI window for configuration and management, with optional auto-start capability, real-time device monitoring, and instant switching between audio devices.

## Product Vision

### Problem Statement
Mac users frequently switch between different audio output devices (MacBook speakers, AirPods, external speakers) throughout their day. The current process requires:
1. Opening System Preferences/Settings
2. Navigating to Sound settings
3. Selecting the output tab
4. Choosing the desired device
5. Closing the settings window

This repetitive task interrupts workflow and reduces productivity, especially for users who frequently transition between meetings, music listening, and focused work sessions.

### Solution
AudioSwitch Pro eliminates this friction by:
- Providing a dedicated app with intuitive UI for device management
- Enabling instant audio device switching via customizable keyboard shortcuts
- Optional auto-start functionality for seamless integration
- Real-time device detection and status monitoring
- Visual device management interface

## Target Users

### Primary Users
1. **Remote Workers**: Frequently switch between video calls (AirPods) and ambient work (speakers)
2. **Content Creators**: Need quick audio switching for recording, editing, and reviewing
3. **Developers**: Switch between focused coding (AirPods) and collaborative sessions (speakers)
4. **Students**: Transition between online classes and personal study sessions

### User Personas

**Sarah - Remote Product Manager**
- Switches audio devices 15+ times daily between meetings and focused work
- Values efficiency and minimal interruption to workflow
- Needs reliable, instant switching with visual confirmation

**Alex - Video Editor**
- Requires precise audio control for different editing phases
- Switches between monitoring speakers and reference headphones
- Needs visual device management and quick access to settings

## Core Features

### 1. Full Application UI
- **Main Window**: Modern SwiftUI interface with device list and controls [MVP: Simple list view]
- **Visual Device Cards**: Show device name, type, connection status, and battery level [MVP: Name and type only]
- **Quick Actions**: One-click switching from the main interface [MVP: ✓]
- **Dock Integration**: App icon in dock with right-click device menu [Post-MVP]

### 2. Keyboard Shortcut System
- **Global Shortcuts**: Work system-wide when app is running [MVP: ✓]
- **Visual Shortcut Editor**: Drag-and-drop or click-to-record interface [MVP: Simple click-to-record]
- **Conflict Detection**: Real-time checking against system shortcuts [Post-MVP]
- **Multiple Shortcut Types**:
  - Quick toggle between last two devices [MVP: ✓]
  - Direct shortcuts for specific devices [Post-MVP]
  - Cycle through favorites [Post-MVP]
  - Mute/unmute shortcuts [Post-MVP]

### 3. Device Management
- **Favorites System**: Star devices for quick access [Post-MVP]
- **Custom Names**: Rename devices for clarity [Post-MVP]
- **Device Icons**: Visual identification with custom icons [MVP: Basic icons only]
- **Smart Sorting**: By usage frequency, connection status, or manual order [Post-MVP]
- **Device Profiles**: Save preferred settings per device [Post-MVP]

### 4. Auto-Start Configuration
- **Optional Feature**: User chooses whether to enable [MVP: ✓]
- **Launch Preferences**:
  - Start minimized to dock [Post-MVP]
  - Start in background (no window) [Post-MVP]
  - Start with main window open [MVP: Default behavior]
- **First Launch Experience**: Clear option during onboarding [MVP: Simple checkbox in settings]

### 5. Real-Time Monitoring
- **Live Device Status**: Connection indicators update instantly [MVP: ✓]
- **Activity Indicators**: Show which device is currently active [MVP: ✓]
- **Connection Type**: Visual indicator for Bluetooth vs wired [MVP: Text label only]
- **Battery Monitoring**: Show battery levels for wireless devices [Post-MVP]

## Technical Architecture

### Core Technologies
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI for entire interface
- **Audio Framework**: AVAudioEngine and Core Audio
- **Bluetooth**: Core Bluetooth for device management
- **Distribution**: Direct download initially, Mac App Store later

### System Requirements
- macOS 12.0 (Monterey) or later
- Apple Silicon (M1/M2/M3) and Intel support
- Storage: ~25MB installed
- Memory usage: <100MB active with UI

### Application Structure
```
AudioSwitchPro.app/
├── Models/
│   ├── AudioDevice.swift
│   ├── ShortcutConfiguration.swift
│   └── UserPreferences.swift
├── Views/
│   ├── MainWindow.swift
│   ├── DeviceListView.swift
│   ├── ShortcutEditorView.swift
│   └── SettingsView.swift
├── ViewModels/
│   ├── AudioDeviceViewModel.swift
│   └── ShortcutViewModel.swift
├── Services/
│   ├── AudioDeviceManager.swift
│   ├── ShortcutManager.swift
│   └── BluetoothManager.swift
└── Utilities/
    ├── KeyboardShortcutHandler.swift
    └── LaunchAtLoginHelper.swift
```

## User Interface Design

### Main Application Window

#### Layout Structure
1. **Sidebar** (200px)
   - Device categories
   - Quick filters
   - Settings access

2. **Main Content Area**
   - Device grid/list view
   - Large, touch-friendly device cards
   - Real-time status updates

3. **Toolbar**
   - View toggles (grid/list)
   - Search field
   - Add device button
   - Settings gear

### Device Card Design
- **Visual Elements**:
  - Device icon (speaker/headphones/custom)
  - Device name (editable)
  - Connection status badge (Connected/Disconnected)
  - Connection type icon (Bluetooth/USB/Internal)
  - Assigned shortcut display
  - Quick switch button

### Shortcut Editor
- **Recording Mode**: Press desired key combination
- **Visual Feedback**: Shows current keys pressed
- **Conflict Warnings**: Immediate feedback
- **Preset Suggestions**: Common combinations

### Settings Window
1. **General Tab**
   - Launch at login toggle
   - Start minimized option
   - Check for updates
   - Sound feedback preferences

2. **Shortcuts Tab**
   - Global enable/disable
   - Shortcut list with edit capabilities
   - Import/export configurations

3. **Appearance Tab**
   - Light/dark/auto theme
   - Icon preferences
   - Compact/comfortable view density

## User Experience Flow

### First Launch
1. **Welcome Screen**
   - App overview with key features
   - Privacy statement (no data collection)
   
2. **Permissions Request**
   - Accessibility for global shortcuts
   - Bluetooth for device detection
   - Optional notifications

3. **Initial Setup**
   - Detect current devices
   - Set up first shortcut
   - Configure auto-start preference

4. **Main Interface**
   - Tour highlighting key features
   - Ready to use

### Daily Usage Flow
1. **With Window Open**
   - Click device card to switch
   - See visual confirmation
   - Adjust settings as needed

2. **Using Shortcuts**
   - Press configured shortcut
   - Audio switches instantly
   - Optional sound/notification confirms change

3. **Background Operation**
   - App runs minimized or hidden
   - Shortcuts remain active
   - Access via dock icon

## Security & Privacy

### Permissions Required
- **Accessibility**: For global keyboard shortcuts
- **Bluetooth**: For wireless device detection
- **Notifications**: For device change alerts (optional)

### Privacy Commitment
- No network connections except for updates
- No analytics or user tracking
- All data stored locally in user preferences
- No third-party integrations

## Performance Targets

### Metrics
- **Launch Time**: <1 second to interactive
- **Switch Speed**: <50ms from trigger to audio change
- **CPU Usage**: <2% with window open, <0.5% minimized
- **Memory**: <100MB with UI, <50MB background
- **Energy Impact**: Low rating in Activity Monitor

## Development Roadmap

### MVP Phase (4 Weeks) - v1.0
- Week 1: Core audio switching + basic UI
- Week 2: Single keyboard shortcut implementation
- Week 3: Settings window + auto-start
- Week 4: Polish + release preparation

### Post-MVP Phases - v2.0+

#### Phase 1: Enhanced Shortcuts (Weeks 5-6)
- Multiple device shortcuts
- Shortcut conflict detection
- Advanced shortcut types

#### Phase 2: Device Management (Weeks 7-8)
- Favorites system
- Custom device names
- Smart sorting options

#### Phase 3: Advanced Features (Weeks 9-10)
- Battery monitoring
- Dock integration
- Appearance options
- Import/export settings

#### Phase 4: Mac App Store (Weeks 11-12)
- Sandboxing
- App Store preparation
- Marketing materials

## Success Metrics

### Quantitative
- Daily active users: 10,000+ within 6 months
- User retention: >80% after 30 days
- Average rating: 4.5+ stars
- Shortcut usage: >90% of users configure shortcuts

### Qualitative
- Positive user reviews about ease of use
- Feature requests indicating engagement
- Community formation around the app
- Professional user testimonials

## Competitive Analysis

### Direct Competitors
1. **Sound Source** - Professional but complex, $39
2. **Audio Hijack** - Overpowered for simple switching, $64
3. **System Preferences** - Free but cumbersome

### Competitive Advantages
- Modern SwiftUI interface
- Free with optional tips
- Focused on switching (not complex routing)
- Native performance
- Privacy-focused

## Distribution Strategy

### Phase 1: Direct Distribution
- Download from website
- GitHub releases
- Homebrew cask

### Phase 2: Mac App Store
- After initial user feedback
- Sandboxed version
- In-app tips for monetization

## Conclusion

AudioSwitch Pro reimagines audio device switching on macOS with a modern, native application that combines the convenience of keyboard shortcuts with a beautiful, functional UI. By focusing on user experience and performance, it will become the go-to solution for Mac users who need efficient audio device management.