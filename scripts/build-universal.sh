#!/bin/bash

# AudioSwitch Pro - Universal Binary Build Script
# Builds for both Intel (x86_64) and Apple Silicon (arm64) architectures

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$PROJECT_DIR/src"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
APP_NAME="AudioSwitchPro"
SCHEME="AudioSwitchPro"
PROJECT_FILE="$SRC_DIR/AudioSwitchPro.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 AudioSwitch Pro Universal Build Script${NC}"
echo -e "${BLUE}==========================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools not found. Please install Xcode."
    exit 1
fi

if [ ! -f "$PROJECT_FILE/project.pbxproj" ]; then
    print_error "Xcode project not found at $PROJECT_FILE"
    exit 1
fi

print_status "Prerequisites check passed"

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Build for Apple Silicon (arm64)
echo -e "${BLUE}🔨 Building for Apple Silicon (arm64)...${NC}"
xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "platform=macOS,arch=arm64" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    ARCHS=arm64 \
    VALID_ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=12.0 \
    build

ARM64_APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$ARM64_APP_PATH" ]; then
    print_error "Apple Silicon build failed - app not found at $ARM64_APP_PATH"
    exit 1
fi

print_status "Apple Silicon build completed"

# Build for Intel (x86_64)
echo -e "${BLUE}🔨 Building for Intel (x86_64)...${NC}"
xcodebuild -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "platform=macOS,arch=x86_64" \
    -derivedDataPath "$BUILD_DIR/DerivedData_x86" \
    ARCHS=x86_64 \
    VALID_ARCHS=x86_64 \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=12.0 \
    build

X86_APP_PATH="$BUILD_DIR/DerivedData_x86/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$X86_APP_PATH" ]; then
    print_error "Intel build failed - app not found at $X86_APP_PATH"
    exit 1
fi

print_status "Intel build completed"

# Create universal binary
echo -e "${BLUE}🔗 Creating universal binary...${NC}"
UNIVERSAL_APP_PATH="$RELEASE_DIR/$APP_NAME.app"

# Copy the ARM64 version as base
cp -R "$ARM64_APP_PATH" "$UNIVERSAL_APP_PATH"

# Use lipo to create universal binary
lipo -create \
    "$ARM64_APP_PATH/Contents/MacOS/$APP_NAME" \
    "$X86_APP_PATH/Contents/MacOS/$APP_NAME" \
    -output "$UNIVERSAL_APP_PATH/Contents/MacOS/$APP_NAME"

print_status "Universal binary created"

# Verify the universal binary
echo -e "${BLUE}🔍 Verifying universal binary...${NC}"
ARCHITECTURES=$(lipo -info "$UNIVERSAL_APP_PATH/Contents/MacOS/$APP_NAME" | awk '{print $NF}')
echo "Supported architectures: $ARCHITECTURES"

if [[ "$ARCHITECTURES" == *"arm64"* ]] && [[ "$ARCHITECTURES" == *"x86_64"* ]]; then
    print_status "Universal binary verification passed"
else
    print_error "Universal binary verification failed"
    exit 1
fi

# Code signing (if certificates are available)
echo -e "${BLUE}🔐 Code signing...${NC}"
if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "Developer ID found, signing app..."
    codesign --force --deep --sign "Developer ID Application" "$UNIVERSAL_APP_PATH"
    print_status "App signed successfully"
else
    print_warning "No Developer ID certificate found. App will be unsigned."
    print_warning "Users may need to allow the app in System Preferences > Security & Privacy"
fi

# Create DMG (optional)
echo -e "${BLUE}📦 Creating DMG...${NC}"
DMG_NAME="AudioSwitchPro-Universal.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"

# Create temporary DMG directory
DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$UNIVERSAL_APP_PATH" "$DMG_TEMP_DIR/"

# Create Applications symlink
ln -sf /Applications "$DMG_TEMP_DIR/Applications"

# Create DMG
hdiutil create -volname "AudioSwitch Pro" \
    -srcfolder "$DMG_TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

print_status "DMG created: $DMG_NAME"

# Create ZIP archive for direct distribution
echo -e "${BLUE}📁 Creating ZIP archive...${NC}"
cd "$RELEASE_DIR"
zip -r "AudioSwitchPro-Universal.zip" "$APP_NAME.app"
cd - > /dev/null

print_status "ZIP archive created: AudioSwitchPro-Universal.zip"

# Display build summary
echo -e "${BLUE}📊 Build Summary${NC}"
echo -e "${BLUE}================${NC}"
echo "✅ Universal app: $UNIVERSAL_APP_PATH"
echo "✅ DMG package: $DMG_PATH"
echo "✅ ZIP archive: $RELEASE_DIR/AudioSwitchPro-Universal.zip"
echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo ""
echo "The app supports:"
echo "  • macOS 12.0 and later"
echo "  • Apple Silicon Macs (M1, M2, M3+)"
echo "  • Intel-based Macs"
echo ""
echo "Distribution options:"
echo "  • Direct download: Distribute the ZIP file"
echo "  • Installer: Use the DMG file"
echo "  • App Store: Additional steps required"