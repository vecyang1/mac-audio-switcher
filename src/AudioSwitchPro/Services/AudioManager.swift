import Foundation
import CoreAudio
import AVFAudio
import AVFoundation
import Combine
import AppKit
import Accelerate

enum AudioManagerError: Error {
    case failedToGetDevices(status: OSStatus)
    case failedToGetProperty(status: OSStatus, property: String)
    case invalidDevice(deviceID: AudioObjectID)
    case virtualDeviceCrash(deviceName: String)
}

class AudioManager: ObservableObject {
    @Published var devices: [AudioDevice] = []
    @Published var activeOutputDeviceID: String?
    @Published var activeInputDeviceID: String?
    @Published var inputLevels: [String: Float] = [:] // DeviceID: Level (0.0 to 1.0)
    @Published var isMonitoringInput = false
    
    var outputDevices: [AudioDevice] {
        devices.filter { $0.isOutput }
    }
    
    var inputDevices: [AudioDevice] {
        devices.filter { !$0.isOutput }
    }
    
    private var lastTwoOutputDeviceIDs: [String] = []
    private var lastTwoInputDeviceIDs: [String] = []
    private let propertyListenerQueue = DispatchQueue(label: "com.audioswitch.propertylistener")
    private var deviceShortcuts: [String: String] = [:] // DeviceID: Shortcut
    private var savedDevices: [AudioDevice] = [] // Keep track of all seen devices
    private var starredDeviceIDs: Set<String> = [] // DeviceIDs that are starred
    private var hiddenDeviceIDs: Set<String> = [] // DeviceIDs that are hidden
    
    // Input monitoring properties
    private var audioEngine: AVAudioEngine?
    private var inputLevelTimer: Timer?
    private var currentInputLevel: Float = 0.0
    private let updateInterval: TimeInterval = 0.1 // 10 Hz update rate
    private var windowObserver: Any?
    
    static let shared = AudioManager()
    
    init() {
        // Check for crash recovery BEFORE doing anything else
        let crashFlagKey = "AudioSwitchPro.CrashFlag"
        let didCrash = UserDefaults.standard.bool(forKey: crashFlagKey)
        
        loadDeviceShortcuts()
        loadSavedDevices()
        loadStarredDevices()
        loadHiddenDevices()
        
        // If we crashed, don't try to restore previous state
        if didCrash {
            print("🚨 AudioManager: Detected previous crash, will reset to safe defaults after initialization")
            // Don't clear the flag here - let AppDelegate do it
        }
        
        // Try to refresh devices safely with crash recovery
        do {
            try safeRefreshDevices()
            
            // If we crashed, immediately reset to safe defaults
            if didCrash {
                print("🔧 Applying crash recovery - resetting to default devices")
                DispatchQueue.main.async { [weak self] in
                    self?.resetToDefaultDevices()
                }
            }
        } catch {
            print("⚠️ Failed to refresh devices on startup: \(error)")
            print("🔧 Attempting recovery with default audio devices...")
            // Force a basic recovery
            DispatchQueue.main.async { [weak self] in
                self?.resetToDefaultDevices()
            }
        }
        
        setupPropertyListeners()
        
        // Add common AirPods device if not already saved (helpful for first time setup)
        addCommonBluetoothDevicesIfNeeded()
    }
    
    private func addCommonBluetoothDevicesIfNeeded() {
        // Only add if no Bluetooth devices are saved yet
        let hasBluetoothDevices = savedDevices.contains { $0.transportType == .bluetooth }
        
        if !hasBluetoothDevices {
            print("📱 No Bluetooth devices found in saved list. User can add them when they connect.")
        }
    }
    
    func refreshDevices() {
        do {
            try safeRefreshDevices()
        } catch {
            print("❌ Error refreshing devices: \(error)")
            // Try to recover by resetting to default devices
            print("⚠️ Attempting to recover with default devices")
            // recoverWithDefaultDevices() // TODO: Implement recovery
        }
    }
    
    private func safeRefreshDevices() throws {
        var devices: [AudioDevice] = []
        
        // Get default devices
        let defaultOutputID = getCurrentOutputDeviceID()
        let defaultInputID = getCurrentInputDeviceID()
        
        // Get all audio devices
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { 
            throw AudioManagerError.failedToGetDevices(status: status)
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var audioDevices = [AudioObjectID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )
        
        guard status == noErr else { 
            throw AudioManagerError.failedToGetDevices(status: status)
        }
        
        for deviceID in audioDevices {
            // Check for output device
            if let device = createAudioDevice(from: deviceID, defaultOutputID: defaultOutputID, defaultInputID: defaultInputID, isOutput: true) {
                devices.append(device)
            }
            // Check for input device
            if let device = createAudioDevice(from: deviceID, defaultOutputID: defaultOutputID, defaultInputID: defaultInputID, isOutput: false) {
                devices.append(device)
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Apply saved shortcuts, starred, and hidden states to devices
            for i in 0..<devices.count {
                devices[i].shortcut = self.deviceShortcuts[devices[i].id]
                devices[i].isOnline = true
                devices[i].isStarred = self.starredDeviceIDs.contains(devices[i].id)
                devices[i].isHidden = self.hiddenDeviceIDs.contains(devices[i].id)
            }
            
            // Update saved devices with current online devices
            for device in devices {
                if let index = self.savedDevices.firstIndex(where: { $0.id == device.id }) {
                    // Preserve starred and hidden states when updating
                    var updatedDevice = device
                    updatedDevice.isStarred = self.savedDevices[index].isStarred
                    updatedDevice.isHidden = self.savedDevices[index].isHidden
                    self.savedDevices[index] = updatedDevice
                } else {
                    self.savedDevices.append(device)
                }
            }
            
            // Check connectivity for saved devices more accurately
            let currentDeviceIDs = Set(devices.map { $0.id })
            for i in 0..<self.savedDevices.count {
                if !currentDeviceIDs.contains(self.savedDevices[i].id) {
                    // For Bluetooth devices, check if they're actually connected via system
                    if self.savedDevices[i].transportType == .bluetooth {
                        self.savedDevices[i].isOnline = self.isBluetoothDeviceConnected(self.savedDevices[i])
                    } else {
                        self.savedDevices[i].isOnline = false
                    }
                    self.savedDevices[i].isActive = false
                    // Preserve starred and hidden states
                    self.savedDevices[i].isStarred = self.starredDeviceIDs.contains(self.savedDevices[i].id)
                    self.savedDevices[i].isHidden = self.hiddenDeviceIDs.contains(self.savedDevices[i].id)
                } else {
                    // Device found in current enumeration, mark as online
                    self.savedDevices[i].isOnline = true
                    // Preserve starred and hidden states
                    self.savedDevices[i].isStarred = self.starredDeviceIDs.contains(self.savedDevices[i].id)
                    self.savedDevices[i].isHidden = self.hiddenDeviceIDs.contains(self.savedDevices[i].id)
                }
            }
            
            // Include offline/connected bluetooth devices in the device list
            var finalDevices = devices
            for savedDevice in self.savedDevices {
                if !currentDeviceIDs.contains(savedDevice.id) && 
                   (savedDevice.transportType == .bluetooth || savedDevice.transportType == .airPlay) {
                    // Use the updated savedDevice with current connectivity status
                    // Make sure to apply starred and hidden states
                    var deviceToAdd = savedDevice
                    deviceToAdd.isStarred = self.starredDeviceIDs.contains(savedDevice.id)
                    deviceToAdd.isHidden = self.hiddenDeviceIDs.contains(savedDevice.id)
                    finalDevices.append(deviceToAdd)
                }
            }
            
            // Sort devices: starred first, then by name
            self.devices = finalDevices.sorted { device1, device2 in
                if device1.isStarred != device2.isStarred {
                    return device1.isStarred
                }
                return device1.name < device2.name
            }
            self.activeOutputDeviceID = defaultOutputID
            self.activeInputDeviceID = defaultInputID
            self.saveSavedDevices()
            
            // Update last two output devices
            if let activeID = self.activeOutputDeviceID {
                if !self.lastTwoOutputDeviceIDs.contains(activeID) {
                    self.lastTwoOutputDeviceIDs.insert(activeID, at: 0)
                    if self.lastTwoOutputDeviceIDs.count > 2 {
                        self.lastTwoOutputDeviceIDs.removeLast()
                    }
                }
            }
            
            // Update last two input devices
            if let activeID = self.activeInputDeviceID {
                if !self.lastTwoInputDeviceIDs.contains(activeID) {
                    self.lastTwoInputDeviceIDs.insert(activeID, at: 0)
                    if self.lastTwoInputDeviceIDs.count > 2 {
                        self.lastTwoInputDeviceIDs.removeLast()
                    }
                }
            }
            
            // Update shortcuts in ShortcutManager
            self.updateShortcutRegistrations()
            
            // Post notification for device changes
            NotificationCenter.default.post(name: Notification.Name("AudioDevicesChanged"), object: nil)
        }
    }
    
    private func createAudioDevice(from deviceID: AudioObjectID, defaultOutputID: String?, defaultInputID: String?, isOutput: Bool) -> AudioDevice? {
        // Get transport type first to handle virtual devices specially
        let transportType = getDeviceTransportType(deviceID)
        
        // Check device streams based on type
        var streamAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &dataSize)
        
        // Be more lenient with virtual devices - they might not report streams properly
        if status != noErr {
            if transportType == .virtual {
                print("⚠️ Virtual device \(deviceID) doesn't report streams properly, including anyway")
                // Continue with virtual devices even if stream check fails
            } else {
                return nil
            }
        }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }
        
        if dataSize > 0 {
            status = AudioObjectGetPropertyData(deviceID, &streamAddress, 0, nil, &dataSize, bufferList)
            if status != noErr && transportType != .virtual {
                return nil
            }
        }
        
        // For virtual devices, assume they have channels even if check fails
        let channelCount = bufferList.pointee.mNumberBuffers
        if channelCount == 0 && transportType != .virtual {
            return nil
        }
        
        // Get device UID
        let uid = getDeviceUID(deviceID) ?? String(deviceID)
        
        // Get device name
        let name = getDeviceName(deviceID) ?? "Unknown Device"
        
        // Filter out only system aggregate devices that confuse users
        // But allow virtual audio routing apps like Loopback Audio
        let lowercasedName = name.lowercased()
        if (name.contains("CADefaultDeviceAggregate") || 
            (lowercasedName.contains("aggregate") && 
             !lowercasedName.contains("loopback") && 
             !lowercasedName.contains("audio hijack") &&
             !lowercasedName.contains("soundflower") &&
             !lowercasedName.contains("blackhole"))) {
            return nil
        }
        
        // Transport type was already retrieved above
        
        let isActive = isOutput ? (uid == defaultOutputID) : (uid == defaultInputID)
        
        return AudioDevice(
            id: uid,
            name: name,
            isOutput: isOutput,
            transportType: transportType,
            isActive: isActive,
            shortcut: nil
        )
    }
    
    private func getDeviceUID(_ deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Check if property exists first (important for virtual devices)
        if !AudioObjectHasProperty(deviceID, &propertyAddress) {
            print("⚠️ Device \(deviceID) has no UID property, using ID as fallback")
            return String(deviceID)
        }
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr else { 
            print("⚠️ Failed to get UID size for device \(deviceID)")
            return nil 
        }
        
        var uid: CFString?
        let uidPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { uidPtr.deallocate() }
        status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, uidPtr)
        uid = uidPtr.pointee
        guard status == noErr, let uid = uid else { 
            print("⚠️ Failed to get UID for device \(deviceID)")
            return nil 
        }
        
        return uid as String
    }
    
    private func getDeviceName(_ deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr else { return nil }
        
        var name: CFString?
        let namePtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { namePtr.deallocate() }
        status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, namePtr)
        name = namePtr.pointee
        guard status == noErr, let name = name else { return nil }
        
        return name as String
    }
    
    private func getDeviceTransportType(_ deviceID: AudioObjectID) -> AudioDevice.TransportType {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var transportType: UInt32 = 0
        var dataSize: UInt32 = UInt32(MemoryLayout<UInt32>.size)
        
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &transportType)
        guard status == noErr else { return .unknown }
        
        switch transportType {
        case kAudioDeviceTransportTypeBluetooth:
            return .bluetooth
        case kAudioDeviceTransportTypeUSB:
            return .usb
        case kAudioDeviceTransportTypeDisplayPort:
            return .displayPort
        case kAudioDeviceTransportTypeHDMI:
            return .hdmi
        case kAudioDeviceTransportTypeBuiltIn:
            return .builtIn
        case kAudioDeviceTransportTypeVirtual:
            return .virtual
        case kAudioDeviceTransportTypeThunderbolt:
            return .thunderbolt
        case kAudioDeviceTransportTypeAirPlay:
            return .airPlay
        default:
            return .unknown
        }
    }
    
    private func getCurrentOutputDeviceID() -> String? {
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
        
        guard status == noErr else { return nil }
        return getDeviceUID(deviceID)
    }
    
    private func getCurrentInputDeviceID() -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
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
        
        guard status == noErr else { return nil }
        return getDeviceUID(deviceID)
    }
    
    func switchToOutputDevice(_ deviceID: String) {
        guard let audioObjectID = getAudioObjectID(from: deviceID) else {
            // If device not found in CoreAudio, check if it's a known Bluetooth device
            if let savedDevice = savedDevices.first(where: { $0.id == deviceID && $0.transportType == .bluetooth }) {
                print("🔵 Device \(savedDevice.name) not in CoreAudio list, attempting Bluetooth reconnection")
                forceConnectBluetoothDevice(savedDevice)
                return
            } else {
                print("❌ Device \(deviceID) not found in CoreAudio and not a known Bluetooth device")
                return
            }
        }
        
        // Check if this is a virtual device
        let device = outputDevices.first { $0.id == deviceID }
        let isVirtualDevice = device?.transportType == .virtual
        
        if isVirtualDevice {
            print("⚠️ Switching to virtual device: \(device?.name ?? deviceID) - using careful error handling")
        }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var mutableDeviceID = audioObjectID
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioObjectID>.size),
            &mutableDeviceID
        )
        
        if status == noErr {
            // Update last two devices for toggle functionality
            if !lastTwoOutputDeviceIDs.contains(deviceID) {
                lastTwoOutputDeviceIDs.insert(deviceID, at: 0)
                if lastTwoOutputDeviceIDs.count > 2 {
                    lastTwoOutputDeviceIDs.removeLast()
                }
            } else {
                // Move to front if already in list
                lastTwoOutputDeviceIDs.removeAll { $0 == deviceID }
                lastTwoOutputDeviceIDs.insert(deviceID, at: 0)
            }
            refreshDevices()
        } else {
            print("❌ Failed to switch to device \(deviceID), status: \(status)")
        }
    }
    
    func switchToInputDevice(_ deviceID: String) {
        guard let audioObjectID = getAudioObjectID(from: deviceID) else {
            print("❌ Input device \(deviceID) not found in CoreAudio")
            return
        }
        
        // Check if switching to/from AirPods
        let deviceName = getDeviceName(audioObjectID)?.lowercased() ?? ""
        let isAirPodsRelated = deviceName.contains("airpod") || 
                               (activeInputDeviceID != nil && 
                                getDeviceName(getAudioObjectID(from: activeInputDeviceID!) ?? 0)?.lowercased().contains("airpod") ?? false)
        
        // Save current output volume and device before switching (for AirPods issue)
        let currentOutputVolume = getCurrentOutputVolume()
        let currentOutputDevice = activeOutputDeviceID
        
        // For AirPods, we need to be more aggressive
        var savedOutputVolumes: [String: Float32] = [:]
        if isAirPodsRelated {
            // Save all output device volumes
            for device in outputDevices {
                if let deviceID = getAudioObjectID(from: device.id) {
                    savedOutputVolumes[device.id] = getDeviceVolume(deviceID)
                }
            }
        }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var mutableDeviceID = audioObjectID
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioObjectID>.size),
            &mutableDeviceID
        )
        
        if status == noErr {
            // Update last two devices for toggle functionality
            if !lastTwoInputDeviceIDs.contains(deviceID) {
                lastTwoInputDeviceIDs.insert(deviceID, at: 0)
                if lastTwoInputDeviceIDs.count > 2 {
                    lastTwoInputDeviceIDs.removeLast()
                }
            } else {
                // Move to front if already in list
                lastTwoInputDeviceIDs.removeAll { $0 == deviceID }
                lastTwoInputDeviceIDs.insert(deviceID, at: 0)
            }
            
            // Add a small delay to prevent audio flash/disturbance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.refreshDevices()
                
                // For AirPods, restore all device volumes
                if isAirPodsRelated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        for (deviceID, volume) in savedOutputVolumes {
                            if let audioDeviceID = self?.getAudioObjectID(from: deviceID) {
                                self?.setDeviceVolume(audioDeviceID, volume: volume)
                            }
                        }
                    }
                }
                
                // Check if output device changed (common with AirPods)
                if let self = self, let currentOutputDevice = currentOutputDevice,
                   self.activeOutputDeviceID != currentOutputDevice {
                    print("⚠️ Output device changed after input switch, reverting...")
                    // Switch back to the original output device
                    self.switchToDevice(currentOutputDevice)
                }
                
                // Always restore volume after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.restoreOutputVolumeIfNeeded(currentOutputVolume)
                }
            }
            
            // Restart input monitoring for the new device
            if isMonitoringInput {
                stopInputMonitoring()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.startInputMonitoring()
                }
            }
        } else {
            print("❌ Failed to switch to input device \(deviceID), status: \(status)")
        }
    }
    
    func switchToDevice(_ deviceID: String) {
        // Determine if it's an input or output device and call appropriate method
        if let device = devices.first(where: { $0.id == deviceID }) {
            if device.isOutput {
                switchToOutputDevice(deviceID)
            } else {
                switchToInputDevice(deviceID)
            }
        }
    }
    
    func toggleBetweenLastTwoOutput() {
        guard lastTwoOutputDeviceIDs.count >= 2 else { return }
        
        if let currentID = activeOutputDeviceID {
            let targetID = currentID == lastTwoOutputDeviceIDs[0] ? lastTwoOutputDeviceIDs[1] : lastTwoOutputDeviceIDs[0]
            switchToOutputDevice(targetID)
        }
    }
    
    func toggleBetweenLastTwoInput() {
        guard lastTwoInputDeviceIDs.count >= 2 else { return }
        
        if let currentID = activeInputDeviceID {
            let targetID = currentID == lastTwoInputDeviceIDs[0] ? lastTwoInputDeviceIDs[1] : lastTwoInputDeviceIDs[0]
            switchToInputDevice(targetID)
        }
    }
    
    func resetToDefaultDevices() {
        print("🔄 Resetting to default audio devices...")
        
        // First refresh devices to get current list
        refreshDevices()
        
        // If devices are empty, try once more after a delay
        if outputDevices.isEmpty && inputDevices.isEmpty {
            print("⚠️ No devices found, retrying after delay...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshDevices()
                self?.performDefaultDeviceReset()
            }
            return
        }
        
        performDefaultDeviceReset()
    }
    
    private func performDefaultDeviceReset() {
        // Find default output device
        var defaultOutputID: String?
        
        // Priority 1: Built-in/MacBook speakers (safest default)
        if let macSpeakers = outputDevices.first(where: { 
            ($0.name.contains("MacBook") && $0.name.contains("Speaker")) ||
            ($0.name.contains("Built-in") && $0.name.contains("Output")) ||
            ($0.transportType == .builtIn && $0.isOutput)
        }) {
            defaultOutputID = macSpeakers.id
            print("✅ Found MacBook Pro Speakers as default output: \(macSpeakers.name)")
        }
        // Priority 2: Any other built-in output
        else if let builtIn = outputDevices.first(where: { 
            $0.transportType == .builtIn && $0.isOutput 
        }) {
            defaultOutputID = builtIn.id
            print("✅ Found built-in output as default: \(builtIn.name)")
        }
        // Priority 3: ANY available output (better than nothing)
        else if let anyOutput = outputDevices.first {
            defaultOutputID = anyOutput.id
            print("⚠️ Using first available output: \(anyOutput.name)")
        }
        
        // Switch to default output
        if let outputID = defaultOutputID {
            print("🔊 Switching to default output: \(outputID)")
            switchToOutputDevice(outputID)
        } else {
            print("❌ No output device found at all!")
        }
        
        // Find default input device (MacBook Pro Microphone)
        if let macMic = inputDevices.first(where: { 
            ($0.name.contains("MacBook") && $0.name.contains("Microphone")) ||
            ($0.name.contains("Built-in") && $0.name.contains("Input")) ||
            ($0.transportType == .builtIn && !$0.isOutput)
        }) {
            print("🎤 Switching to default input: \(macMic.name)")
            switchToInputDevice(macMic.id)
        }
        // Fallback to any available input
        else if let anyInput = inputDevices.first {
            print("⚠️ Using first available input: \(anyInput.name)")
            switchToInputDevice(anyInput.id)
        } else {
            print("❌ No input device found at all!")
        }
    }
    
    func setDevice(_ device: AudioDevice) {
        // If device is offline and Bluetooth, try to reconnect it first
        if !device.isOnline && device.transportType == .bluetooth {
            print("🔵 Attempting to reconnect Bluetooth device: \(device.name)")
            forceConnectBluetoothDevice(device)
        } else {
            switchToDevice(device.id)
        }
    }
    
    
    private func forceConnectBluetoothDevice(_ device: AudioDevice) {
        print("🔵 Attempting to connect Bluetooth device: \(device.name) (\(device.id))")
        
        // Show user-friendly notification
        DispatchQueue.main.async {
            // TODO: Replace with UserNotifications.framework
            print("🔔 Connecting to \(device.name)")
            print("   Please ensure your \(device.name) is powered on and nearby. Put it in your ears if it's AirPods.")
        }
        
        // Method 1: Try blueutil if available (simple approach)
        let deviceIdClean = device.id.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: "")
        
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = "/usr/bin/env"
            task.arguments = ["bash", "-c", "which blueutil >/dev/null 2>&1 && blueutil --connect \(deviceIdClean) 2>/dev/null || echo 'blueutil unavailable'"]
            
            do {
                try task.run()
                task.waitUntilExit()
                print("📡 Attempted blueutil connection to: \(deviceIdClean)")
            } catch {
                print("⚠️ blueutil command failed: \(error)")
            }
        }
        
        // Method 2: Continuously monitor for device availability and switch when ready
        var attempts = 0
        let maxAttempts = 15 // Increased attempts for more patience
        
        func checkAndSwitch() {
            attempts += 1
            print("🔄 Waiting for \(device.name) to become available (attempt \(attempts)/\(maxAttempts))")
            
            // Refresh devices to get latest state
            self.refreshDevices()
            
            // Check if device is now available in CoreAudio
            if let audioObjectID = self.getAudioObjectID(from: device.id) {
                print("✅ \(device.name) found in CoreAudio, switching now")
                
                var propertyAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                var mutableDeviceID = audioObjectID
                let status = AudioObjectSetPropertyData(
                    AudioObjectID(kAudioObjectSystemObject),
                    &propertyAddress,
                    0,
                    nil,
                    UInt32(MemoryLayout<AudioObjectID>.size),
                    &mutableDeviceID
                )
                
                if status == noErr {
                    print("✅ Successfully switched to \(device.name)")
                    
                    // Update last two devices for toggle functionality (assuming output for Bluetooth)
                    if !self.lastTwoOutputDeviceIDs.contains(device.id) {
                        self.lastTwoOutputDeviceIDs.insert(device.id, at: 0)
                        if self.lastTwoOutputDeviceIDs.count > 2 {
                            self.lastTwoOutputDeviceIDs.removeLast()
                        }
                    } else {
                        // Move to front if already in list
                        self.lastTwoOutputDeviceIDs.removeAll { $0 == device.id }
                        self.lastTwoOutputDeviceIDs.insert(device.id, at: 0)
                    }
                    self.refreshDevices()
                    
                    // Show success notification
                    DispatchQueue.main.async {
                        // TODO: Replace with UserNotifications.framework
                        print("✅ Connected!")
                        print("   Successfully switched to \(device.name)")
                    }
                } else {
                    print("❌ Failed to switch to \(device.name), status: \(status)")
                }
                return
            }
            
            // If not found and we haven't exceeded max attempts, try again
            if attempts < maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    checkAndSwitch()
                }
            } else {
                print("⏰ Timed out waiting for \(device.name) to connect")
                
                // Show timeout notification with helpful instruction
                DispatchQueue.main.async {
                    // TODO: Replace with UserNotifications.framework
                    print("⚠️ Device Not Found")
                    print("   Please manually connect \(device.name) in System Settings > Bluetooth, then try switching again.")
                }
            }
        }
        
        // Start checking after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkAndSwitch()
        }
    }
    
    private func getAudioObjectID(from uid: String) -> AudioObjectID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { return nil }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var audioDevices = [AudioObjectID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )
        
        guard status == noErr else { return nil }
        
        for deviceID in audioDevices {
            if let deviceUID = getDeviceUID(deviceID), deviceUID == uid {
                return deviceID
            }
        }
        
        return nil
    }
    
    private func setupPropertyListeners() {
        // Listen for default output device changes
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                manager.propertyListenerQueue.async {
                    DispatchQueue.main.async {
                        manager.refreshDevices()
                    }
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        // Listen for default input device changes
        propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                manager.propertyListenerQueue.async {
                    DispatchQueue.main.async {
                        manager.refreshDevices()
                    }
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        // Listen for device list changes
        propertyAddress.mSelector = kAudioHardwarePropertyDevices
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                manager.propertyListenerQueue.async {
                    DispatchQueue.main.async {
                        manager.refreshDevices()
                    }
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
    
    // MARK: - Device Shortcut Management
    
    func setShortcut(_ shortcut: String, for deviceID: String) {
        print("🎯 Setting shortcut '\(shortcut)' for device: \(deviceID)")
        deviceShortcuts[deviceID] = shortcut
        saveDeviceShortcuts()
        
        // Update the device in the array
        if let index = devices.firstIndex(where: { $0.id == deviceID }) {
            devices[index].shortcut = shortcut
            print("✅ Updated device array with shortcut")
        }
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        updateShortcutRegistrations()
    }
    
    func clearShortcut(for deviceID: String) {
        deviceShortcuts.removeValue(forKey: deviceID)
        saveDeviceShortcuts()
        
        // Update the device in the array
        if let index = devices.firstIndex(where: { $0.id == deviceID }) {
            devices[index].shortcut = nil
        }
        
        updateShortcutRegistrations()
    }
    
    private func loadDeviceShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "deviceShortcuts"),
           let shortcuts = try? JSONDecoder().decode([String: String].self, from: data) {
            deviceShortcuts = shortcuts
        }
    }
    
    private func saveDeviceShortcuts() {
        if let data = try? JSONEncoder().encode(deviceShortcuts) {
            UserDefaults.standard.set(data, forKey: "deviceShortcuts")
        }
    }
    
    private func loadSavedDevices() {
        if let data = UserDefaults.standard.data(forKey: "savedAudioDevices"),
           let devices = try? JSONDecoder().decode([AudioDevice].self, from: data) {
            savedDevices = devices
        }
    }
    
    private func saveSavedDevices() {
        if let data = try? JSONEncoder().encode(savedDevices) {
            UserDefaults.standard.set(data, forKey: "savedAudioDevices")
        }
    }
    
    // MARK: - Star/Hide Device Management
    
    func toggleStar(for deviceID: String) {
        if starredDeviceIDs.contains(deviceID) {
            starredDeviceIDs.remove(deviceID)
        } else {
            starredDeviceIDs.insert(deviceID)
        }
        saveStarredDevices()
        
        // Update the device in the devices array
        if let index = devices.firstIndex(where: { $0.id == deviceID }) {
            devices[index].isStarred = starredDeviceIDs.contains(deviceID)
            
            // Also update in saved devices to ensure persistence
            if let savedIndex = savedDevices.firstIndex(where: { $0.id == deviceID }) {
                savedDevices[savedIndex].isStarred = starredDeviceIDs.contains(deviceID)
            } else {
                // If not in saved devices, add it
                var deviceToSave = devices[index]
                deviceToSave.isStarred = starredDeviceIDs.contains(deviceID)
                savedDevices.append(deviceToSave)
            }
        }
        
        // Save the updated saved devices
        saveSavedDevices()
        
        // Refresh to reorder
        refreshDevices()
    }
    
    func hideDevice(_ deviceID: String) {
        hiddenDeviceIDs.insert(deviceID)
        saveHiddenDevices()
        
        // Update the device in the devices array
        if let index = devices.firstIndex(where: { $0.id == deviceID }) {
            devices[index].isHidden = true
            
            // Also update in saved devices to ensure persistence
            if let savedIndex = savedDevices.firstIndex(where: { $0.id == deviceID }) {
                savedDevices[savedIndex].isHidden = true
            } else {
                // If not in saved devices, add it
                var deviceToSave = devices[index]
                deviceToSave.isHidden = true
                savedDevices.append(deviceToSave)
            }
        }
        
        // Save the updated saved devices
        saveSavedDevices()
        
        // Force UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func unhideDevice(_ deviceID: String) {
        hiddenDeviceIDs.remove(deviceID)
        saveHiddenDevices()
        
        // Update the device in the array
        if let index = devices.firstIndex(where: { $0.id == deviceID }) {
            devices[index].isHidden = false
        }
        
        // Update saved devices too
        if let index = savedDevices.firstIndex(where: { $0.id == deviceID }) {
            savedDevices[index].isHidden = false
        }
        
        // Save the updated saved devices
        saveSavedDevices()
        
        refreshDevices()
    }
    
    func getHiddenDevices() -> [AudioDevice] {
        // Get all devices that are marked as hidden
        var hiddenDevices: [AudioDevice] = []
        
        // First check current devices
        for device in devices where hiddenDeviceIDs.contains(device.id) {
            var hiddenDevice = device
            hiddenDevice.isHidden = true
            hiddenDevices.append(hiddenDevice)
        }
        
        // Then check saved devices for any that aren't in current devices
        for savedDevice in savedDevices where hiddenDeviceIDs.contains(savedDevice.id) {
            if !hiddenDevices.contains(where: { $0.id == savedDevice.id }) {
                var hiddenDevice = savedDevice
                hiddenDevice.isHidden = true
                hiddenDevices.append(hiddenDevice)
            }
        }
        
        return hiddenDevices
    }
    
    private func loadStarredDevices() {
        if let data = UserDefaults.standard.data(forKey: "starredDeviceIDs"),
           let starred = try? JSONDecoder().decode(Set<String>.self, from: data) {
            starredDeviceIDs = starred
        }
    }
    
    private func saveStarredDevices() {
        if let data = try? JSONEncoder().encode(starredDeviceIDs) {
            UserDefaults.standard.set(data, forKey: "starredDeviceIDs")
        }
    }
    
    private func loadHiddenDevices() {
        if let data = UserDefaults.standard.data(forKey: "hiddenDeviceIDs"),
           let hidden = try? JSONDecoder().decode(Set<String>.self, from: data) {
            hiddenDeviceIDs = hidden
        }
    }
    
    private func saveHiddenDevices() {
        if let data = try? JSONEncoder().encode(hiddenDeviceIDs) {
            UserDefaults.standard.set(data, forKey: "hiddenDeviceIDs")
        }
    }
    
    private func isBluetoothDeviceConnected(_ device: AudioDevice) -> Bool {
        // Guard against nil or invalid device
        guard device.transportType == .bluetooth else { return false }
        
        // Use a simple and fast check first - assume Bluetooth devices are connected if they were recently online
        // This prevents flapping between online/offline states
        
        // Skip blueutil check for now to avoid potential crashes
        // Just check if it's a known Bluetooth device
        
        // For devices that were recently seen, assume they're still connectable
        // This prevents devices from flapping between online/offline when they're actually available
        if savedDevices.contains(where: { $0.id == device.id && $0.transportType == .bluetooth }) {
            // If we've seen this device before and it's Bluetooth, be more lenient about marking it offline
            print("🔵 \(device.name) is a known Bluetooth device - keeping as potentially available")
            return true
        }
        
        print("🔍 \(device.name) not found in connectivity checks")
        return false
    }
    
    func addBluetoothDeviceManually(name: String, id: String) {
        let bluetoothDevice = AudioDevice(
            id: id,
            name: name,
            isOutput: true,
            transportType: .bluetooth,
            isActive: false,
            shortcut: nil,
            isOnline: false
        )
        
        // Add to saved devices if not already present
        if !savedDevices.contains(where: { $0.id == id }) {
            savedDevices.append(bluetoothDevice)
            saveSavedDevices()
            
            // Refresh the UI
            DispatchQueue.main.async {
                self.refreshDevices()
            }
        }
    }
    
    func refreshShortcuts() {
        updateShortcutRegistrations()
    }
    
    func toggleAppPanel() {
        DispatchQueue.main.async {
            // Get all app windows and find the main content window
            let allWindows = NSApplication.shared.windows
            print("🔍 Found \\(allWindows.count) total windows")
            
            // Find main window - look for ContentView or main app window
            let mainWindow = allWindows.first { window in
                // Check if it's the main content window (not settings, not panel)
                let isMainWindow = !window.isSheet && 
                                 window.level == .normal &&
                                 (window.contentViewController != nil || window.contentView != nil)
                
                if isMainWindow {
                    print("📋 Found potential main window: \\(window.title) - visible: \\(window.isVisible)")
                }
                return isMainWindow
            }
            
            if let window = mainWindow {
                if window.isVisible && !window.isMiniaturized {
                    // Hide the window (but keep app running)
                    window.orderOut(nil)
                    print("🫥 Main panel hidden - app running in background")
                } else {
                    // Show and bring to front
                    window.setIsVisible(true)
                    window.makeKeyAndOrderFront(nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    print("👁️ Main panel shown and focused")
                }
            } else {
                // If no window found, activate the app to create/show window
                print("🚨 No main window found, activating app")
                NSApplication.shared.activate(ignoringOtherApps: true)
                
                // Try again after a short delay to find the window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let newWindow = NSApplication.shared.windows.first(where: { !$0.isSheet && $0.level == .normal }) {
                        newWindow.makeKeyAndOrderFront(nil)
                        print("🆕 Found and showed new window")
                    }
                }
            }
        }
    }
    
    private func updateShortcutRegistrations() {
        print("🔄 Updating shortcut registrations...")
        
        // Clear all existing shortcuts
        ShortcutManager.shared.clearAllShortcuts()
        
        // Register global panel toggle shortcut (optional)
        if let globalShortcut = UserDefaults.standard.globalShortcut, !globalShortcut.isEmpty {
            print("📝 Registering global panel shortcut: \(globalShortcut)")
            ShortcutManager.shared.registerShortcut(globalShortcut, identifier: "global.panel") {
                print("🪟 Global panel shortcut triggered")
                self.toggleAppPanel()
            }
        }
        
        // Register device-specific shortcuts
        for device in devices {
            if let shortcut = device.shortcut {
                print("📝 Registering device shortcut: \(shortcut) for \(device.name)")
                ShortcutManager.shared.registerShortcut(shortcut, identifier: "device.\(device.id)") {
                    print("🎵 Device shortcut triggered for: \(device.name)")
                    self.switchToDevice(device.id)
                }
            }
        }
        
        print("✅ Shortcut registration complete")
    }
    
    // MARK: - Input Level Monitoring
    
    func startInputMonitoring() {
        guard !isMonitoringInput else { return }
        
        // Check microphone permission first
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startMonitoringEngine()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.startMonitoringEngine()
                    }
                }
            }
        default:
            print("❌ Microphone access denied")
        }
    }
    
    private func startMonitoringEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        
        // Validate format
        guard format.sampleRate > 0 && format.channelCount > 0 else {
            print("❌ Invalid audio format")
            return
        }
        
        // Install tap with small buffer size for efficiency
        inputNode.installTap(onBus: 0, bufferSize: 512, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isMonitoringInput = true
            
            // Start timer for UI updates
            inputLevelTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                self?.updateInputLevels()
            }
            
            print("🎤 Started input monitoring")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func stopInputMonitoring() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        inputLevelTimer?.invalidate()
        inputLevelTimer = nil
        
        isMonitoringInput = false
        currentInputLevel = 0.0
        
        // Clear all levels
        DispatchQueue.main.async {
            self.inputLevels = [:]
        }
        
        print("🛑 Stopped input monitoring")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        var rms: Float = 0.0
        
        // Use Accelerate framework for efficient RMS calculation
        for channel in 0..<channelCount {
            var channelRMS: Float = 0.0
            vDSP_rmsqv(channelData[channel], 1, &channelRMS, vDSP_Length(frameLength))
            rms += channelRMS
        }
        
        rms /= Float(channelCount)
        
        // Convert to decibels and normalize
        let db = 20 * log10(max(0.000001, rms))
        let normalized = (db + 60) / 60 // Map -60dB to 0dB to 0.0 to 1.0
        
        // Smooth the value
        currentInputLevel = (currentInputLevel * 0.7) + (normalized * 0.3)
        currentInputLevel = max(0, min(1, currentInputLevel))
    }
    
    private func updateInputLevels() {
        if let activeInputID = activeInputDeviceID {
            DispatchQueue.main.async {
                self.inputLevels[activeInputID] = self.currentInputLevel
                
                // Set inactive devices to 0
                for device in self.inputDevices {
                    if device.id != activeInputID {
                        self.inputLevels[device.id] = 0.0
                    }
                }
            }
        }
    }
    
    func getInputLevel(for deviceID: String) -> Float {
        return inputLevels[deviceID] ?? 0.0
    }
    
    // MARK: - Volume Management (for AirPods issue)
    
    private func getCurrentOutputVolume() -> Float32 {
        guard let activeOutputID = activeOutputDeviceID,
              let deviceID = getAudioObjectID(from: activeOutputID) else { return 0.0 }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volume: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &volume
        )
        
        if status == noErr {
            return volume
        }
        
        return 0.0
    }
    
    private func restoreOutputVolumeIfNeeded(_ previousVolume: Float32) {
        guard let activeOutputID = activeOutputDeviceID,
              let deviceID = getAudioObjectID(from: activeOutputID) else { return }
        
        let currentVolume = getCurrentOutputVolume()
        
        // If volume changed at all, restore it (AirPods can have sudden jumps)
        if abs(currentVolume - previousVolume) > 0.01 {
            setDeviceVolume(deviceID, volume: previousVolume)
        }
    }
    
    private func getDeviceVolume(_ deviceID: AudioObjectID) -> Float32 {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volume: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &volume
        )
        
        return status == noErr ? volume : 0.0
    }
    
    private func setDeviceVolume(_ deviceID: AudioObjectID, volume: Float32) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volumeToSet = volume
        
        let status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float32>.size),
            &volumeToSet
        )
        
        if status == noErr {
            print("🔊 Set device volume to \(Int(volume * 100))%")
        }
    }
}