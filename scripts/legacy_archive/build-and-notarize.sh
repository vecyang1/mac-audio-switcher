#!/bin/bash

# AudioSwitch Pro - Build and Notarize Script
# This script builds, signs, and notarizes the app for direct distribution

set -e  # Exit on error

echo "🚀 AudioSwitch Pro - Build and Notarize Script"
echo "============================================="

# Configuration
PROJECT_PATH="src/AudioSwitchPro.xcodeproj"
SCHEME="AudioSwitchPro"
CONFIGURATION="Release"
EXPORT_PATH="build/Release"
APP_NAME="AudioSwitchPro"
BUNDLE_ID="com.vecyang.AudioSwitchPro"

# Get the development team from Xcode
echo "📋 Checking Xcode configuration..."
TEAM_ID=$(xcodebuild -showBuildSettings -project "$PROJECT_PATH" -configuration "$CONFIGURATION" | grep DEVELOPMENT_TEAM | head -1 | awk '{print $3}')

if [ -z "$TEAM_ID" ] || [ "$TEAM_ID" = '""' ]; then
    echo "❌ Error: No development team found!"
    echo ""
    echo "Please:"
    echo "1. Open AudioSwitchPro.xcodeproj in Xcode"
    echo "2. Select the project in the navigator"
    echo "3. Go to Signing & Capabilities"
    echo "4. Select your team from the dropdown"
    echo "5. Run this script again"
    exit 1
fi

echo "✅ Found Team ID: $TEAM_ID"

# Clean build folder
echo ""
echo "🧹 Cleaning build folder..."
rm -rf "$EXPORT_PATH"
mkdir -p "$EXPORT_PATH"

# Archive the app
echo ""
echo "🔨 Building and archiving..."
xcodebuild -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$EXPORT_PATH/$APP_NAME.xcarchive" \
    clean archive \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE="Automatic"

# Export for Developer ID distribution
echo ""
echo "📦 Exporting for Developer ID distribution..."

# Create export options plist
cat > "$EXPORT_PATH/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# Export the archive
xcodebuild -exportArchive \
    -archivePath "$EXPORT_PATH/$APP_NAME.xcarchive" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_PATH/ExportOptions.plist"

# Check if app was exported
if [ ! -d "$EXPORT_PATH/$APP_NAME.app" ]; then
    echo "❌ Error: App was not exported successfully!"
    exit 1
fi

echo "✅ App exported successfully!"

# Create ZIP for notarization
echo ""
echo "🗜️ Creating ZIP for notarization..."
cd "$EXPORT_PATH"
ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip"
cd - > /dev/null

# Get Apple ID for notarization
echo ""
echo "📝 Preparing for notarization..."
echo ""
echo "Enter your Apple ID email (viviscallers@gmail.com):"
read -r APPLE_ID

# Submit for notarization
echo ""
echo "🚀 Submitting for notarization..."
echo "This may take 5-30 minutes. Please be patient..."

xcrun notarytool submit "$EXPORT_PATH/$APP_NAME.zip" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --wait

# Check notarization status
if [ $? -eq 0 ]; then
    echo "✅ Notarization successful!"
    
    # Staple the notarization
    echo ""
    echo "📌 Stapling notarization..."
    xcrun stapler staple "$EXPORT_PATH/$APP_NAME.app"
    
    echo "✅ Stapling complete!"
else
    echo "❌ Notarization failed!"
    echo "Check the error messages above for details."
    exit 1
fi

# Create final distribution DMG or ZIP
echo ""
echo "📀 Creating distribution package..."
echo "Choose format:"
echo "1) DMG (recommended - professional)"
echo "2) ZIP (simple - faster)"
read -r -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        echo "Creating DMG..."
        # Simple DMG creation
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$EXPORT_PATH/$APP_NAME.app" \
            -ov -format UDZO \
            "$EXPORT_PATH/$APP_NAME.dmg"
        
        echo "✅ Created: $EXPORT_PATH/$APP_NAME.dmg"
        echo ""
        echo "🎉 Success! Your notarized app is ready for distribution:"
        echo "   $EXPORT_PATH/$APP_NAME.dmg"
        ;;
    2)
        echo "Creating distribution ZIP..."
        cd "$EXPORT_PATH"
        rm -f "$APP_NAME-Distribution.zip"
        ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-Distribution.zip"
        cd - > /dev/null
        
        echo "✅ Created: $EXPORT_PATH/$APP_NAME-Distribution.zip"
        echo ""
        echo "🎉 Success! Your notarized app is ready for distribution:"
        echo "   $EXPORT_PATH/$APP_NAME-Distribution.zip"
        ;;
    *)
        echo "Invalid choice. Creating ZIP by default..."
        cd "$EXPORT_PATH"
        ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-Distribution.zip"
        cd - > /dev/null
        echo "✅ Created: $EXPORT_PATH/$APP_NAME-Distribution.zip"
        ;;
esac

echo ""
echo "📊 Summary:"
echo "- App is signed with Developer ID"
echo "- App is notarized by Apple"
echo "- Ready for distribution at $9.99"
echo "- Upload to Gumroad/Paddle to start selling!"
echo ""
echo "🚀 Next steps:"
echo "1. Upload to your sales platform"
echo "2. Set price to $9.99"
echo "3. Start marketing!"