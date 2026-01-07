#!/bin/bash

echo "🔍 Finding your Apple Developer Team..."
echo ""

# Method 1: Check from Xcode preferences
echo "Checking Xcode accounts..."
PLIST_PATH="$HOME/Library/Preferences/com.apple.dt.Xcode.plist"

if [ -f "$PLIST_PATH" ]; then
    # Try to extract team info from Xcode preferences
    /usr/libexec/PlistBuddy -c "Print :Accounts" "$PLIST_PATH" 2>/dev/null | grep -A5 "viviscallers@gmail.com" || echo "Account not found in preferences"
fi

# Method 2: Check keychain for certificates
echo ""
echo "Checking keychain for certificates..."
security find-identity -v | grep -E "Developer ID Application|Apple Development" | head -5

# Method 3: Try to get from Xcode directly
echo ""
echo "Attempting to get team from Xcode..."
echo ""
echo "⚠️  IMPORTANT: Please do the following:"
echo ""
echo "1. Xcode should now be open with your project"
echo "2. Click on 'AudioSwitchPro' in the file navigator (left sidebar)"
echo "3. Select 'AudioSwitchPro' under TARGETS"
echo "4. Click the 'Signing & Capabilities' tab"
echo "5. Check ✅ 'Automatically manage signing'"
echo "6. In the Team dropdown, you should see your friend's team"
echo "7. Select the team"
echo ""
echo "The team name should look something like:"
echo "   - Personal Team (if using personal account)"
echo "   - Company Name (ABCDEF123) - the text in parentheses is the Team ID"
echo ""
echo "Once you've selected the team, we can continue with the build process."