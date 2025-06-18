#!/bin/bash

# Direct build script for AudioSwitch Pro without Xcode project

echo "Building AudioSwitch Pro directly..."

# Set up directories
SRC_DIR="$(dirname "$0")/../src/AudioSwitchPro"
BUILD_DIR="$(dirname "$0")/../build"
APP_NAME="AudioSwitchPro"

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

# Create Info.plist
cat > "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.vecyang.AudioSwitchPro</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>AudioSwitch Pro needs accessibility permissions to register global keyboard shortcuts.</string>
</dict>
</plist>
EOF

# Find all Swift files
SWIFT_FILES=$(find "$SRC_DIR" -name "*.swift" -type f | tr '\n' ' ')

# Compile the app
echo "Compiling Swift files..."
swiftc $SWIFT_FILES \
    -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -sdk $(xcrun --show-sdk-path) \
    -target arm64-apple-macos12.0 \
    -framework SwiftUI \
    -framework CoreAudio \
    -framework Carbon \
    -framework ServiceManagement \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -Xlinker -rpath -Xlinker /usr/lib/swift

# Check if compilation succeeded
if [ $? -eq 0 ]; then
    echo "Build succeeded!"
    echo "App location: $BUILD_DIR/$APP_NAME.app"
    
    # Copy resources
    cp -r "$SRC_DIR/Assets.xcassets" "$BUILD_DIR/$APP_NAME.app/Contents/Resources/" 2>/dev/null || true
    
    # Make it executable
    chmod +x "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"
    
    # Open the app
    open "$BUILD_DIR/$APP_NAME.app"
else
    echo "Build failed!"
    exit 1
fi