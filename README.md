# AudioSwitch Pro

A modern macOS application for seamless audio device switching with customizable keyboard shortcuts.

## Features (MVP v1.0)

- 🎵 **Instant Audio Switching** - Switch between audio devices with one click
- 🖥️ **Beautiful Native UI** - Clean, modern SwiftUI interface
- ⌨️ **Global Shortcut** - Toggle between last two devices with a keyboard shortcut
- 🚀 **Auto-start Option** - Launch at login (optional)
- ✅ **Simple & Fast** - No complex settings, just works

### Coming in v2.0
- Multiple device shortcuts
- Device favorites and custom names
- Battery level monitoring
- Advanced device management

## Requirements

- macOS 12.0 (Monterey) or later
- Apple Silicon or Intel Mac

## Installation

### Direct Download
Coming soon - download the latest release from the [Releases](https://github.com/vecyang1/mac-audio-switcher/releases) page.

### Build from Source
```bash
git clone https://github.com/vecyang1/mac-audio-switcher.git
cd mac-audio-switcher
open AudioSwitchPro.xcodeproj
```

## Usage

1. **First Launch**: Grant necessary permissions for keyboard shortcuts and Bluetooth access
2. **Configure Shortcuts**: Assign keyboard shortcuts to your favorite audio devices
3. **Switch Devices**: Use your shortcuts or click devices in the main window

## Project Structure

```
mac-audio-switcher/
├── docs/                    # Documentation
│   ├── PRODUCT_DESIGN.md   # Full product vision
│   ├── MVP_REQUIREMENTS.md # MVP feature scope
│   └── MVP_ARCHITECTURE.md # Simplified architecture
├── AudioSwitchPro/         # Main application
│   ├── App/               # App entry point
│   ├── Models/            # Simple data model
│   ├── Views/             # SwiftUI views (3 files)
│   ├── Services/          # AudioManager only
│   └── Utilities/         # ShortcutManager only
└── README.md              # This file
```

## Development

### Prerequisites
- Xcode 15.0 or later
- Swift 5.9+
- macOS 12.0+ SDK

### Building
1. Clone the repository
2. Open `AudioSwitchPro.xcodeproj` in Xcode
3. Select your development team in project settings
4. Build and run (⌘R)

### Contributing
Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## Privacy

AudioSwitch Pro is designed with privacy in mind:
- No analytics or tracking
- No network connections (except optional update checks)
- All preferences stored locally
- No data collection

## License

Copyright © 2024 Vec Yang. All rights reserved.

## Support

- [Report Issues](https://github.com/vecyang1/mac-audio-switcher/issues)
- [Feature Requests](https://github.com/vecyang1/mac-audio-switcher/issues/new?labels=enhancement)

## MVP Roadmap (4 weeks)

### Week 1
- [x] Core audio switching functionality
- [x] Basic SwiftUI interface
- [ ] Device list with one-click switching

### Week 2
- [ ] Single keyboard shortcut implementation
- [ ] Simple settings window

### Week 3
- [ ] Auto-start functionality
- [ ] UI polish and testing

### Week 4
- [ ] Final testing
- [ ] GitHub release preparation
- [ ] Direct download distribution

### Future (v2.0+)
- [ ] Multiple device shortcuts
- [ ] Device favorites and renaming
- [ ] Mac App Store release
- [ ] Advanced features from full product design

---

Made with ❤️ for the Mac community