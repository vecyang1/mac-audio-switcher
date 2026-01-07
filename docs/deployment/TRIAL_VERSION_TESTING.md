# AudioSwitchPro Trial Version Testing Guide

## Overview
The trial version of AudioSwitchPro includes:
- 1-day trial period (configurable)
- License key activation via Zylvie API
- Admin bypass code: `AdmincodeV`
- Trial restrictions when expired

## Testing the Trial System

### 1. First Launch (Trial Not Started)
- App should start normally
- Trial banner should show "Trial: 1 days remaining"
- All features work normally

### 2. Testing Trial Expiration
To test trial expiration without waiting:
1. In Settings, click "Reset License (Debug)" (only visible in debug builds)
2. Or manually edit the trial start date in the code

### 3. Testing License Activation

#### Admin Code
- Click "Activate" in trial banner or settings
- Enter: `AdmincodeV`
- Should activate immediately without API call

#### Valid License Key
- Purchase a license from: https://zylvie.com/products/edit/D8nvR78n
- Enter the UUID license key provided
- Should validate via API and activate

#### Invalid License Key
Test with:
- Random text: Should show "Invalid license key format"
- Wrong UUID: Should show "Invalid license key"

### 4. Trial Restrictions
When trial expires:
- Device switching is disabled
- Shows "Trial Expired" banner
- Activation prompt appears on launch
- Device list remains visible (read-only)

## API Configuration
- Product ID: `D8nvR78n`
- API Key: `459c750d7730496f9e6c57191808633d`
- Base URL: `https://api.zylvie.com`

## Build Notes
1. Open Xcode and verify all files are added correctly
2. Files added:
   - `LicenseManager.swift`
   - `ActivationView.swift`
   - `TrialBannerView.swift`
   - `LicenseStatusView.swift`

## Distribution
For the trial version:
- Use different bundle ID: `com.vecyang.AudioSwitchProTrial`
- Separate app name: "AudioSwitch Pro Trial"
- Can be distributed alongside free version

## Troubleshooting

### Xcode Build Issues
If you get file not found errors:
1. Open project in Xcode
2. Remove red (missing) file references
3. Re-add files manually from correct paths
4. Clean build folder (Cmd+Shift+K)
5. Build again

### Trial Not Working
- Check UserDefaults for corrupted data
- Use debug reset button in settings
- Verify system date/time is correct

### License Activation Fails
- Check internet connection
- Verify API endpoints are accessible
- Check license key format (must be valid UUID)