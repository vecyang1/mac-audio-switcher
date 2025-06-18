#!/bin/bash

# AudioSwitch Pro - Build, Install and Run Script
# Builds the app, installs to /Applications, and launches it

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 AudioSwitch Pro - Build & Run"
echo "================================"

# Step 1: Build
echo ""
echo "📦 Step 1: Building app..."
"$SCRIPT_DIR/build-simple-universal.sh"

# Check if build succeeded
if [ ! -d "$PROJECT_DIR/release/AudioSwitchPro.app" ]; then
    echo "❌ Build failed!"
    exit 1
fi

# Step 2: Install
echo ""
echo "🔄 Step 2: Installing to /Applications..."

# Check if app is running
if pgrep -x "AudioSwitchPro" > /dev/null; then
    echo "⚠️  AudioSwitchPro is currently running"
    echo "Closing the app..."
    killall AudioSwitchPro
    sleep 1
fi

# Remove old version if exists
if [ -d "/Applications/AudioSwitchPro.app" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "/Applications/AudioSwitchPro.app"
fi

# Copy new version
echo "📦 Installing new version..."
cp -R "$PROJECT_DIR/release/AudioSwitchPro.app" "/Applications/"

# Step 3: Launch
echo ""
echo "🚀 Step 3: Launching AudioSwitchPro..."
open "/Applications/AudioSwitchPro.app"

echo ""
echo "✅ Done! AudioSwitch Pro has been built, installed, and launched."
echo ""
echo "📍 Location: /Applications/AudioSwitchPro.app"
echo "🔧 Settings are preserved across updates"