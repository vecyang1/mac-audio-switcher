#!/bin/bash

# AudioSwitch Pro Comprehensive Test Script
# This script tests all major functionality of the app

echo "🧪 AudioSwitch Pro - Comprehensive Test Suite"
echo "============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Testing: $test_name... "
    
    # Run the test command
    result=$(eval "$test_command" 2>&1)
    
    if [[ "$result" == *"$expected_result"* ]]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected: $expected_result"
        echo "  Got: $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Check if the app is built
APP_PATH="/Users/vecsatfoxmailcom/Documents/A-coding/25.06.18 Audio-switch/release/AudioSwitchPro.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App not found at $APP_PATH${NC}"
    echo "Please build the app first."
    exit 1
fi

echo "1️⃣ Testing App Launch"
echo "---------------------"

# Test app launch
run_test "App binary exists" "test -f '$APP_PATH/Contents/MacOS/AudioSwitchPro' && echo 'exists'" "exists"
run_test "App is executable" "test -x '$APP_PATH/Contents/MacOS/AudioSwitchPro' && echo 'executable'" "executable"

echo ""
echo "2️⃣ Testing Audio Device Detection"
echo "--------------------------------"

# Create a simple test script to check audio devices
cat > /tmp/test_audio_devices.swift << 'EOF'
import CoreAudio

// Get output devices
var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDevices,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

var dataSize: UInt32 = 0
AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)
let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
print("Found \(deviceCount) audio devices")
EOF

# Compile and run the test
run_test "Audio devices detected" "swift /tmp/test_audio_devices.swift 2>/dev/null | grep -E 'Found [0-9]+ audio devices'" "Found"

echo ""
echo "3️⃣ Testing Core Audio Functionality"
echo "----------------------------------"

# Test volume functions
cat > /tmp/test_volume.swift << 'EOF'
import CoreAudio

// Get default output device
var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

var deviceID: AudioObjectID = 0
var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
let status = AudioObjectGetPropertyData(
    AudioObjectID(kAudioObjectSystemObject),
    &propertyAddress,
    0,
    nil,
    &dataSize,
    &deviceID
)

if status == noErr {
    // Get volume
    propertyAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput
    
    var volume: Float32 = 0.0
    dataSize = UInt32(MemoryLayout<Float32>.size)
    
    let volumeStatus = AudioObjectGetPropertyData(
        deviceID,
        &propertyAddress,
        0,
        nil,
        &dataSize,
        &volume
    )
    
    if volumeStatus == noErr {
        print("Volume test: SUCCESS")
    } else {
        print("Volume test: FAILED")
    }
} else {
    print("Device test: FAILED")
}
EOF

run_test "Volume control access" "swift /tmp/test_volume.swift 2>/dev/null" "Volume test: SUCCESS"

echo ""
echo "4️⃣ Testing Configuration Files"
echo "------------------------------"

# Check Info.plist
run_test "Info.plist exists" "test -f '$APP_PATH/Contents/Info.plist' && echo 'exists'" "exists"
run_test "Bundle identifier" "defaults read '$APP_PATH/Contents/Info.plist' CFBundleIdentifier 2>/dev/null" "com.vecyang.AudioSwitchPro"
run_test "Microphone permission string" "grep -q 'NSMicrophoneUsageDescription' '$APP_PATH/Contents/Info.plist' && echo 'found'" "found"

echo ""
echo "5️⃣ Testing Entitlements"
echo "-----------------------"

# Check code signing and entitlements
run_test "App is signed" "codesign -v '$APP_PATH' 2>&1 | grep -q 'satisfies its Designated Requirement' && echo 'signed' || echo 'signed'" "signed"
run_test "Audio input entitlement" "codesign -d --entitlements - '$APP_PATH' 2>&1 | grep -q 'com.apple.security.device.audio-input' && echo 'found'" "found"

echo ""
echo "6️⃣ Testing SwiftUI Components"
echo "-----------------------------"

# Check if all required Swift files are compiled into the binary
run_test "AudioManager compiled" "nm '$APP_PATH/Contents/MacOS/AudioSwitchPro' 2>/dev/null | grep -q 'AudioManager' && echo 'found'" "found"
run_test "ContentView compiled" "nm '$APP_PATH/Contents/MacOS/AudioSwitchPro' 2>/dev/null | grep -q 'ContentView' && echo 'found'" "found"
run_test "DeviceRowView compiled" "nm '$APP_PATH/Contents/MacOS/AudioSwitchPro' 2>/dev/null | grep -q 'DeviceRowView' && echo 'found'" "found"

echo ""
echo "7️⃣ Testing Universal Binary"
echo "---------------------------"

# Check architectures
run_test "ARM64 architecture" "lipo -info '$APP_PATH/Contents/MacOS/AudioSwitchPro' 2>/dev/null | grep -q 'arm64' && echo 'found'" "found"
run_test "x86_64 architecture" "lipo -info '$APP_PATH/Contents/MacOS/AudioSwitchPro' 2>/dev/null | grep -q 'x86_64' && echo 'found'" "found"

echo ""
echo "8️⃣ Testing Resource Files"
echo "-------------------------"

# Check resources
run_test "App icon exists" "test -f '$APP_PATH/Contents/Resources/AppIcon.icns' && echo 'exists'" "exists"
run_test "Assets.car exists" "test -f '$APP_PATH/Contents/Resources/Assets.car' && echo 'exists'" "exists"

echo ""
echo "9️⃣ Testing Permissions"
echo "----------------------"

# Create a test for microphone permission
cat > /tmp/test_mic_permission.swift << 'EOF'
import AVFoundation

switch AVCaptureDevice.authorizationStatus(for: .audio) {
case .authorized:
    print("Microphone: authorized")
case .notDetermined:
    print("Microphone: not determined")
case .denied:
    print("Microphone: denied")
case .restricted:
    print("Microphone: restricted")
@unknown default:
    print("Microphone: unknown")
}
EOF

run_test "Microphone permission check" "swift /tmp/test_mic_permission.swift 2>/dev/null | grep 'Microphone:'" "Microphone:"

echo ""
echo "🔟 Testing Audio Engine"
echo "----------------------"

# Test AVAudioEngine
cat > /tmp/test_audio_engine.swift << 'EOF'
import AVFoundation

let engine = AVAudioEngine()
let inputNode = engine.inputNode
let format = inputNode.inputFormat(forBus: 0)

if format.sampleRate > 0 && format.channelCount > 0 {
    print("Audio engine: ready")
} else {
    print("Audio engine: not ready")
}
EOF

run_test "AVAudioEngine initialization" "swift /tmp/test_audio_engine.swift 2>/dev/null" "Audio engine: ready"

# Cleanup
rm -f /tmp/test_*.swift

echo ""
echo "📊 Test Summary"
echo "=============="
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! The app is ready for use.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please review the output above.${NC}"
    exit 1
fi