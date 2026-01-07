#!/bin/bash

# AudioSwitch Pro - Uninstall Script
# Removes the app and related configuration files
# Usage: ./uninstall.sh

set -e

APP_NAME="AudioSwitchPro"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🗑️  AudioSwitch Pro Uninstaller${NC}"
echo "=============================="

# Kill running app
if pgrep -x "$APP_NAME" > /dev/null; then
    echo "🛑 Stopping $APP_NAME..."
    pkill -x "$APP_NAME"
    sleep 1
fi

# Remove App
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "📦 Removing /Applications/$APP_NAME.app..."
    rm -rf "/Applications/$APP_NAME.app"
else
    echo "⚠️  App not found in /Applications"
fi

# Ask to remove preferences
read -p "Do you want to remove usage data and preferences? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Removing preferences..."
    rm -f ~/Library/Preferences/com.vecyang.AudioSwitchPro.plist
    rm -rf ~/Library/Application\ Support/AudioSwitchPro
    rm -rf ~/Library/Caches/com.vecyang.AudioSwitchPro
    echo "✅ Preferences removed."
fi

echo -e "${GREEN}✅ Uninstall Complete!${NC}"
