# Global Panel Toggle Shortcut

## 🪟 New Panel Show/Hide Functionality

The global shortcut now toggles the AudioSwitch Pro panel visibility instead of switching between devices. This provides quick access to the app from anywhere on macOS.

## 🎯 How It Works

### Show/Hide Panel
- **Panel visible**: Shortcut hides the window
- **Panel hidden**: Shortcut shows and brings window to front
- **Works from anywhere**: Even when app is in background

### Optional Feature
- **Default**: No global shortcut set (disabled)
- **User choice**: Enable/disable in Settings
- **Flexible**: User can choose not to use it at all

## ⚙️ Settings Configuration

### Enable Global Shortcut
1. **Open Settings** (gear icon)
2. **Find "Global Panel Shortcut"** section
3. **Toggle "Enable global shortcut to show/hide panel"**
4. **Set your desired shortcut** (e.g., ⌘⌥A, ⌘⌥Space, etc.)

### Disable Global Shortcut
1. **Open Settings**
2. **Toggle OFF "Enable global shortcut to show/hide panel"**
3. **Shortcut is cleared** and no longer active

## 🎵 Usage Examples

### Quick Access Workflow
1. **Working in other apps** → Press shortcut → Panel appears
2. **Check/switch audio device** → Press shortcut → Panel hides
3. **Continue working** seamlessly

### Power User Setup
- **Panel shortcut**: ⌘⌥A (show/hide panel)
- **Device shortcuts**: ⌘⌥1, ⌘⌥2, ⌘⌥3 (direct device switching)
- **Best of both worlds**: Quick panel access + direct device control

### Minimal Setup
- **No panel shortcut**: Disable global shortcut entirely
- **Only device shortcuts**: ⌘⌥1, ⌘⌥2, etc.
- **Clean approach**: No extra shortcuts, just device switching

## 💡 Why This Change?

### Better User Experience
- **More logical**: Panel toggle vs device switching
- **More flexible**: Users can choose to disable it
- **More efficient**: Direct device shortcuts are faster
- **Less confusing**: Clear purpose for each shortcut type

### Cleaner Design
- **Optional feature**: Not forced on users
- **Clear labeling**: "Show/hide panel" vs ambiguous "toggle"
- **User control**: Enable/disable as preferred
- **Progressive disclosure**: Advanced users can set it up

## 🔧 Technical Details

### Window Management
- **Hide**: Uses `window.orderOut(nil)`
- **Show**: Uses `window.makeKeyAndOrderFront(nil)`
- **Focus**: Activates app with `NSApplication.shared.activate()`
- **Smart detection**: Finds main window automatically

### State Management
- **Persistent**: Setting saved in UserDefaults
- **Reactive**: Changes apply immediately
- **Safe**: No shortcuts registered if disabled
- **Clean**: Properly unregisters when disabled

## ✨ Benefits

### For Casual Users
- **Optional**: Can completely ignore if not needed
- **Simple**: Just use device shortcuts directly
- **No confusion**: Clear what each shortcut does

### For Power Users
- **Quick access**: Instant panel visibility control
- **Workflow integration**: Hide/show as needed
- **Customizable**: Choose preferred key combination
- **Efficient**: Fast access without dock/spotlight

### For All Users
- **Choice**: Enable or disable as preferred
- **Clarity**: Clear purpose for panel vs device shortcuts
- **Flexibility**: Multiple ways to interact with audio devices
- **Control**: Full user control over shortcut behavior