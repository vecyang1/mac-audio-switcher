#!/bin/bash

# AudioSwitch Pro Auto-Install Script
# Automatically updates the app in /Applications whenever you rebuild

echo "🔄 AudioSwitch Pro Auto-Install"
echo "==============================="

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILT_APP="$PROJECT_DIR/release/AudioSwitchPro.app"
INSTALLED_APP="/Applications/AudioSwitchPro.app"

# Check if built app exists
if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Error: Built app not found at $BUILT_APP"
    echo "Please run ./scripts/build-simple-universal.sh first"
    exit 1
fi

# Check if app is running
if pgrep -x "AudioSwitchPro" > /dev/null; then
    echo "⚠️  AudioSwitchPro is currently running"
    echo "Closing the app..."
    killall AudioSwitchPro
    sleep 1
fi

# Remove old version if exists
if [ -d "$INSTALLED_APP" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "$INSTALLED_APP"
fi

# Copy new version
echo "📦 Installing new version..."
cp -R "$BUILT_APP" "$INSTALLED_APP"

# Verify installation
if [ -d "$INSTALLED_APP" ]; then
    echo "✅ Successfully installed to /Applications/"
    
    # Launch the app
    echo "🚀 Launching AudioSwitchPro..."
    open "$INSTALLED_APP"
else
    echo "❌ Installation failed"
    exit 1
fi

echo ""
echo "🎉 Done! AudioSwitchPro has been updated and launched."