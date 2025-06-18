#!/bin/bash

# Build script for AudioSwitch Pro

echo "Building AudioSwitch Pro..."

cd "$(dirname "$0")/../src"

# Clean build folder
rm -rf build

# Build the app
xcodebuild -project AudioSwitchPro.xcodeproj \
           -scheme AudioSwitchPro \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "Build succeeded!"
    echo "App location: $(pwd)/build/Build/Products/Release/AudioSwitchPro.app"
    
    # Open the app
    open build/Build/Products/Release/AudioSwitchPro.app
else
    echo "Build failed!"
    exit 1
fi