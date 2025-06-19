# AudioSwitch Pro Update System Documentation

## Overview
This document describes the auto-update mechanism implemented for AudioSwitch Pro, designed for a paid app distributed through a WordPress website.

## Architecture

### 1. UpdateService.swift
Located at: `src/AudioSwitchPro/Services/UpdateService.swift`

**Key Features:**
- Checks for updates from a WordPress API endpoint
- Compares version numbers to determine if update is available
- Shows system notifications when app is in background
- Provides methods to open purchase page

**Configuration Required:**
```swift
// Replace this URL with your actual WordPress endpoint
private let updateCheckURL = "https://yourwebsite.com/api/audioswitchpro/version"
```

### 2. UpdateNotificationView.swift
Located at: `src/AudioSwitchPro/Views/UpdateNotificationView.swift`

**Components:**
- Main update notification dialog
- Release notes viewer
- Update badge for settings

### 3. WordPress API Endpoint

Your WordPress site needs to provide an endpoint that returns JSON in this format:

```json
{
  "version": "1.1.0",
  "release_notes": "- New feature: Virtual device warnings\n- Improved menu bar icon\n- Bug fixes",
  "purchase_url": "https://yourwebsite.com/purchase/audioswitchpro"
}
```

**Example WordPress Implementation:**
```php
// Add to your WordPress theme's functions.php or as a plugin
add_action('rest_api_init', function () {
    register_rest_route('api/audioswitchpro', '/version', array(
        'methods' => 'GET',
        'callback' => 'get_audioswitchpro_version',
        'permission_callback' => '__return_true'
    ));
});

function get_audioswitchpro_version() {
    return array(
        'version' => '1.1.0',
        'release_notes' => 'New features and improvements...',
        'purchase_url' => 'https://yourwebsite.com/purchase/audioswitchpro'
    );
}
```

## Integration Steps

### 1. Add Files to Xcode Project
The following files need to be added to your Xcode project:
- `src/AudioSwitchPro/Services/UpdateService.swift`
- `src/AudioSwitchPro/Views/UpdateNotificationView.swift`

### 2. Enable Update Code in SettingsView
Uncomment the update-related code in `SettingsView.swift`:
- Line 14: `@StateObject private var updateService = UpdateService.shared`
- Line 228: `UpdateBadgeView()`
- Lines 247-250: Latest version display
- Lines 256-263: Check Now button functionality
- Lines 234-238: Auto update check toggle functionality
- Lines 321-324: Auto update check on appear
- Lines 326-328: Update notification sheet

### 3. Settings Available to Users
- **Automatic Update Checks**: Toggle in Settings > Updates
- **Manual Check**: "Check Now" button in Settings
- **Update Notification**: Shows when update is available
- **Get Update**: Opens purchase page in browser

## Update Flow

1. **Automatic Checks** (if enabled):
   - Checks on app launch
   - Checks every 24 hours while running

2. **Manual Checks**:
   - User clicks "Check Now" in Settings

3. **When Update Found**:
   - Shows badge in Settings
   - Shows notification if app in background
   - User can view release notes
   - "Get Update" opens purchase URL

## Version Comparison Logic

The update service compares version numbers component by component:
- 1.0.0 < 1.0.1
- 1.0.9 < 1.1.0
- 2.0.0 > 1.9.9

## Testing

To test the update system:
1. Set up a test endpoint that returns a higher version
2. Click "Check Now" in Settings
3. Verify update notification appears
4. Test "Get Update" opens correct URL

## Security Considerations

- Use HTTPS for your WordPress endpoint
- Consider adding authentication if needed
- Validate version data before using
- Don't include direct download links in public endpoints

## Menu Bar Icon Change

The menu bar icon was changed from `speaker.wave.2.fill` to `speaker.circle.fill` for better visibility and distinction from other apps.

Location: `AudioSwitchProApp.swift` line 268