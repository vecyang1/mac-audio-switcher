# Troubleshooting Team Access Issues

## The Problem:
- You're logged into App Store Connect with viviscallers@gmail.com
- But in Xcode, you only see "ve cs (Personal Team)"
- Your friend's team doesn't appear

## Possible Causes:

### 1. Invitation Not Properly Accepted
- Check your email for an invitation from Apple
- Make sure you clicked "Accept Invitation"
- The invitation must be accepted with the SAME Apple ID

### 2. Wrong Account Type
Your friend might have:
- **Apple Developer account** (for App Store) - This won't work for notarization
- **Apple Developer Program** (paid $99/year) - This is what you need

### 3. Role Permissions
You need:
- "Developer" or "Admin" role
- "Marketing" or "Sales" roles cannot create certificates

## How to Fix:

### Step 1: Verify in App Store Connect
1. Click on your name (Weibiao Pan) in top right
2. Look for a dropdown showing different teams
3. If you see only your personal account, the invitation isn't working

### Step 2: In Xcode
1. Open Xcode → Settings (⌘,)
2. Go to Accounts tab
3. Check if viviscallers@gmail.com shows:
   - "Personal Team" only = Free account
   - "Apple Developer Program" = Paid account with team access

### Step 3: Ask Your Friend
Have them verify:
1. They have a PAID Apple Developer Program account ($99/year)
2. They added you with "Developer" or "Admin" role
3. They sent the invitation to viviscallers@gmail.com

## Alternative Solutions:

### If Team Access Doesn't Work:
1. **Have your friend build it** - Send them the project
2. **Get your own developer account** - $99/year
3. **Distribute unsigned** - Users will get security warnings

### For Unsigned Distribution:
```bash
# Build without signing
xcodebuild -project AudioSwitchPro.xcodeproj \
  -scheme AudioSwitchPro \
  -configuration Release \
  -archivePath ./build/AudioSwitchPro.xcarchive \
  archive \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# Create DMG
./create-dmg.sh
```

Users will need to:
1. Right-click the app
2. Select "Open"
3. Click "Open" in the warning dialog
4. Go to System Settings → Privacy & Security
5. Allow the app to run