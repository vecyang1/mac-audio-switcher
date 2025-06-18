# AudioSwitch Pro

A modern macOS application for seamless audio device switching with customizable keyboard shortcuts.

## Features

- 🎵 **Instant Audio Switching** - Switch between audio devices with customizable keyboard shortcuts
- 🖥️ **Beautiful Native UI** - Modern SwiftUI interface designed for macOS
- ⌨️ **Global Shortcuts** - Control audio devices from anywhere on your Mac
- 🔄 **Real-time Monitoring** - See device status, battery levels, and connection state
- 🚀 **Auto-start Option** - Configure the app to launch at login
- 🎯 **Smart Device Management** - Favorite devices, custom names, and smart sorting

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
│   └── PRODUCT_DESIGN.md   # Detailed product design document
├── src/                    # Source code
│   └── AudioSwitchPro/     # Main application
│       ├── Models/         # Data models
│       ├── Views/          # SwiftUI views
│       ├── ViewModels/     # View models
│       ├── Services/       # Core services
│       └── Utilities/      # Helper utilities
├── tests/                  # Unit and UI tests
├── scripts/                # Build and utility scripts
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

## Roadmap

- [x] Core audio switching functionality
- [x] SwiftUI interface design
- [ ] Keyboard shortcut implementation
- [ ] Auto-start functionality
- [ ] Beta testing
- [ ] Mac App Store release

---

Made with ❤️ for the Mac community