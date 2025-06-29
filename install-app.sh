#!/bin/bash

# AudioSwitchPro Installation Script
# This script handles the deployment of AudioSwitchPro to both /Applications and the release folder
# Usage: ./install-app.sh [debug|release]
# Default: release

BUILD_CONFIG=${1:-release}
PROJECT_DIR="/Users/vecsatfoxmailcom/Documents/A-coding/25.06.18 Audio-switch"
DERIVED_DATA="/Users/vecsatfoxmailcom/Library/Developer/Xcode/DerivedData/AudioSwitchPro-ecyhmnlhwueaqdcwcoxgxdxvpizb"

# Kill any running instances
echo "Stopping any running AudioSwitchPro instances..."
pkill -f AudioSwitchPro || true
sleep 1

# Determine source based on build configuration
if [ "$BUILD_CONFIG" = "debug" ]; then
    SOURCE_APP="$DERIVED_DATA/Build/Products/Debug/AudioSwitchPro.app"
    echo "Using Debug build..."
else
    SOURCE_APP="$DERIVED_DATA/Build/Products/Release/AudioSwitchPro.app"
    echo "Using Release build..."
fi

# Check if source app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Error: Build not found at $SOURCE_APP"
    echo "Please build the project first with: xcodebuild -configuration $BUILD_CONFIG"
    exit 1
fi

# Copy to release folder (for distribution)
echo "Copying to release folder..."
mkdir -p "$PROJECT_DIR/release"
cp -R "$SOURCE_APP" "$PROJECT_DIR/release/"

# Copy to /Applications (for local use)
echo "Installing AudioSwitchPro to /Applications..."
cp -R "$SOURCE_APP" /Applications/

# Launch the new version
echo "Launching AudioSwitchPro..."
open /Applications/AudioSwitchPro.app

echo "✅ Installation complete!"
echo "📦 Release copy available at: $PROJECT_DIR/release/AudioSwitchPro.app"