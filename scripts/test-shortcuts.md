# Testing AudioSwitch Pro Device Shortcuts

## How to Test Individual Device Shortcuts:

1. **Open AudioSwitch Pro**
   - Launch the app from Applications or build folder

2. **Set up Device Shortcuts**
   - Click "Device Shortcuts" button at the bottom
   - For each device you want to control:
     - Click "Set Shortcut" button
     - Press a key combination (e.g., ⌘⌥1, ⌘⌥2, etc.)
     - The shortcut should appear in the button

3. **Test the Shortcuts**
   - Close the Device Shortcuts window
   - Try pressing the shortcuts you assigned
   - Each shortcut should immediately switch to that specific device

4. **Verify in Console**
   - Open Console.app
   - Filter for "AudioSwitchPro" 
   - You should see debug messages when shortcuts are triggered

## Example Shortcut Assignments:
- MacBook Pro Speakers: ⌘⌥1
- AirPods Pro: ⌘⌥2  
- External Display: ⌘⌥3
- Global Toggle: ⌘⌥A (default)

## Troubleshooting:
- Make sure app has Accessibility permissions
- Check Console for error messages
- Restart app if shortcuts stop working
- Try different key combinations if conflicts exist

## Expected Behavior:
✅ Each device can have its own shortcut
✅ Shortcuts work system-wide (even when app is in background)
✅ Visual feedback shows shortcut assignments
✅ No conflicts between device shortcuts and global toggle
✅ Shortcuts persist between app restarts