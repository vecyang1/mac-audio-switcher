# Mac App Store Requirements - What Needs to Change

## 🔴 CURRENT BLOCKERS

### 1. Enable Sandboxing (Breaks Everything)
```xml
<!-- AudioSwitchPro.entitlements -->
<key>com.apple.security.app-sandbox</key>
<true/> <!-- MUST be true -->
```

### 2. Remove Carbon API (Breaks Shortcuts)
```swift
// ShortcutManager.swift - ALL of this must go:
RegisterEventHotKey() // ❌ NOT allowed
InstallEventHandler() // ❌ NOT allowed
// Must use NSEvent.addLocalMonitor only (not global!)
```

### 3. Fix Audio Permissions
```xml
<!-- Need temporary exception (may be rejected) -->
<key>com.apple.security.temporary-exception.audio-unit-host</key>
<true/>
```

### 4. Update Bundle ID
```
com.vecyang.AudioSwitchPro → com.[teamID].AudioSwitchPro
```

## 📋 Complete App Store Checklist

### Phase 1: Code Changes (2-3 weeks)
- [ ] Enable full sandboxing
- [ ] Remove ALL Carbon API usage
- [ ] Rewrite shortcuts (local only, no global)
- [ ] Add App Store receipt validation
- [ ] Update all entitlements
- [ ] Remove launch at login (use SMAppService)
- [ ] Add in-app purchase code (if needed)

### Phase 2: App Store Connect Setup
1. Create app in App Store Connect
2. Fill in:
   - App name: AudioSwitch Pro
   - Bundle ID: com.[teamID].AudioSwitchPro
   - Primary category: Utilities
   - Secondary category: Productivity
   - Price: $9.99

3. App Information:
   - Content rights: Original content
   - Age rating: 4+
   - Copyright: Your name/company

4. Prepare:
   - [ ] App icon (1024x1024)
   - [ ] Screenshots (2880x1800 for Retina)
   - [ ] App preview video (optional)
   - [ ] Description (max 4000 chars)
   - [ ] Keywords (100 chars max)
   - [ ] What's New (for updates)

### Phase 3: Metadata
```
Name: AudioSwitch Pro

Subtitle: Instant Audio Device Switching

Description:
Switch between your Mac's audio devices instantly! No more clicking through System Settings.

AudioSwitch Pro makes it simple to switch between AirPods, speakers, and other audio devices with just a click or keyboard shortcut.

Features:
• One-click device switching
• Keyboard shortcuts for each device  
• Menu bar access
• Visual device status
• Background operation
• Native Apple Silicon support

Perfect for:
- Switching between AirPods and speakers
- Video calls with different devices
- Music production workflows
- Anyone who uses multiple audio devices

Simple, fast, and designed for macOS.

Keywords: audio,switch,airpods,sound,device,speaker,output,utility,productivity,shortcuts
```

## 🚫 What You'll LOSE on App Store

1. **Global Shortcuts** - Main feature gone!
2. **System Integration** - Limited control
3. **Power Features** - Many restrictions
4. **Quick Updates** - 1-2 week review wait
5. **Revenue** - 30% to Apple

## ✅ Recommended Path Forward

### Option A: Developer ID Distribution (BEST)
1. Keep ALL current features
2. Sign with your Developer ID
3. Notarize for Gatekeeper
4. Sell directly via Gumroad
5. Launch this week!

### Option B: BOTH Versions
1. "AudioSwitch Pro" - Full version (direct sales)
2. "AudioSwitch Lite" - App Store version (limited features)

### Option C: Wait for App Store Changes
Apple may eventually allow more system integration, but don't hold your breath.

## Next Steps with Developer Account

```bash
# 1. Add your Apple ID to Xcode
# Xcode → Settings → Accounts → Add Apple ID

# 2. Create signing certificate
# Select your team in project settings

# 3. Archive and notarize
Product → Archive
Window → Organizer → Distribute App → Developer ID → Upload

# 4. After notarization completes
xcrun stapler staple AudioSwitchPro.app

# 5. Create DMG for distribution
create-dmg AudioSwitchPro.app

# Ready for direct sales!
```

## My Recommendation

1. **This week**: Launch direct sales version
2. **Get feedback**: See what users want
3. **Later**: Maybe create limited App Store version
4. **Focus**: On making money NOW with the full-featured version

Your app is PERFECT as-is. Don't cripple it for App Store rules!