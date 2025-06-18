#!/bin/bash

# AudioSwitch Pro - Simple Universal Binary Build Script
# Creates ONE app that works on both Intel and Apple Silicon Macs

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/src"
RELEASE_DIR="$PROJECT_DIR/release"
APP_NAME="AudioSwitchPro"
SCHEME="AudioSwitchPro"
PROJECT_FILE="$SRC_DIR/AudioSwitchPro.xcodeproj"

echo "🚀 Building Universal AudioSwitch Pro App"
echo "========================================"

# Clean and create release directory
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build universal binary directly
echo "🔨 Building Universal Binary..."
xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$RELEASE_DIR/Build" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=12.0 \
    build

# Copy the built app
BUILT_APP="$RELEASE_DIR/Build/Build/Products/Release/$APP_NAME.app"
FINAL_APP="$RELEASE_DIR/$APP_NAME.app"

if [ -d "$BUILT_APP" ]; then
    cp -R "$BUILT_APP" "$FINAL_APP"
    echo "✅ Universal app created: $FINAL_APP"
    
    # Verify universal binary
    echo "🔍 Verifying universal binary..."
    lipo -info "$FINAL_APP/Contents/MacOS/$APP_NAME"
    
    # Create ZIP for distribution
    echo "📦 Creating distribution package..."
    cd "$RELEASE_DIR"
    zip -r "AudioSwitchPro-Universal-v1.0.zip" "$APP_NAME.app"
    
    echo ""
    echo "🎉 SUCCESS! Universal app ready for distribution:"
    echo "  📱 App: $FINAL_APP"
    echo "  📦 ZIP: $RELEASE_DIR/AudioSwitchPro-Universal-v1.0.zip"
    echo ""
    echo "This ONE app works on:"
    echo "  ✅ Apple Silicon Macs (M1, M2, M3+)"
    echo "  ✅ Intel-based Macs"
    echo "  ✅ macOS 12.0 and later"
    
else
    echo "❌ Build failed - app not found"
    exit 1
fi