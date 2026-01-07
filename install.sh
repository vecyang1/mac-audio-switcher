#!/bin/bash

# AudioSwitch Pro - Unified Install Script
# Builds the project (Universal Binary) and installs to /Applications
# Usage: ./install.sh

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_DIR/src"
BUILD_DIR="$PROJECT_DIR/build/install_temp"
APP_NAME="AudioSwitchPro"
PROJECT_FILE="$SRC_DIR/AudioSwitchPro.xcodeproj"
SCHEME="AudioSwitchPro"

# Formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 AudioSwitch Pro Installation${NC}"
echo "================================="

# Check dependencies
echo -e "${BLUE}📋 Checking environment...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found. Please install Xcode Command Line Tools.${NC}"
    exit 1
fi

# Cleanup previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Kill running app
if pgrep -x "$APP_NAME" > /dev/null; then
    echo -e "${BLUE}🛑 Stopping running instance...${NC}"
    pkill -x "$APP_NAME" || true
    sleep 1
fi

# Build
echo -e "${BLUE}🔨 Building Universal Binary (Intel + Apple Silicon)...${NC}"
xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -quiet \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=12.0 \
    build

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo -e "${RED}❌ Build failed. App not found at $BUILT_APP${NC}"
    exit 1
fi

# Install
echo -e "${BLUE}📦 Installing to /Applications...${NC}"

# Remove existing app in /Applications if it exists
if [ -d "/Applications/$APP_NAME.app" ]; then
    rm -rf "/Applications/$APP_NAME.app"
fi

# Copy new app
cp -R "$BUILT_APP" "/Applications/"

# Cleanup build artifacts
echo -e "${BLUE}🧹 Cleaning up build artifacts...${NC}"
rm -rf "$BUILD_DIR"

# Launch
echo -e "${BLUE}🚀 Launching $APP_NAME...${NC}"
open "/Applications/$APP_NAME.app"

echo -e "${GREEN}✅ Installation Complete!${NC}"
