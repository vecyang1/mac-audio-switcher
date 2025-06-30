# Xcode Developer ID Signing Guide

## Step 1: Configure Team in Xcode

1. **Open Xcode** and load AudioSwitchPro.xcodeproj
2. Click on **AudioSwitchPro** (the project file) in the navigator
3. Select **AudioSwitchPro** under TARGETS
4. Click the **Signing & Capabilities** tab

You should see:
```
[ ] Automatically manage signing
Team: [None]
Bundle Identifier: com.vecyang.AudioSwitchPro
```

5. Check ✅ **Automatically manage signing**
6. In the **Team** dropdown, select your friend's developer team
7. Xcode will automatically create the necessary certificates

## Step 2: Build and Archive

### From Xcode Menu:
1. **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** on the left
3. Change **Build Configuration** to **Release**
4. Click **Close**

5. **Product** → **Clean Build Folder** (⌘⇧K)
6. **Product** → **Archive**
7. Wait for build to complete (1-2 minutes)

## Step 3: Export with Developer ID

When the Organizer window opens:

1. Select your archive (should be highlighted)
2. Click **Distribute App** button
3. Select **Developer ID** ← IMPORTANT! (Not App Store)
4. Click **Next**
5. Select **Upload** (for notarization)
6. Click **Next**
7. Select **Automatic** signing
8. Click **Next**
9. Review and click **Upload**

## Step 4: Wait for Notarization

Apple will:
1. Scan your app (5-30 minutes)
2. Send email when complete
3. Automatically staple the notarization

## Step 5: Export Final App

Once notarized:
1. In Organizer, select the archive again
2. Click **Distribute App**
3. Select **Developer ID**
4. Select **Export** (not upload this time)
5. Follow prompts to save the app

## What You Get

✅ AudioSwitchPro.app that:
- Is signed with Developer ID
- Is notarized by Apple
- Opens without warnings
- Has ALL features working
- Ready to sell for $9.99

## Quick Terminal Alternative

If you prefer, just run:
```bash
cd "/Users/vecsatfoxmailcom/Documents/A-coding/25.06.18 Audio-switch"
./build-and-notarize.sh
```

This automates the entire process!

## Troubleshooting

### "No Team Selected"
- Make sure you're signed into Xcode (Settings → Accounts)
- Select the team in Signing & Capabilities

### "Profile doesn't match"
- Let Xcode automatically manage signing
- It will create the right certificates

### Notarization fails
- Check your Apple ID password
- Make sure you're using an app-specific password if 2FA is enabled

## Next Steps

1. Upload notarized app to Gumroad
2. Set price to $9.99
3. Start selling!

Remember: This uses Developer ID, NOT App Store distribution. All your features will work!