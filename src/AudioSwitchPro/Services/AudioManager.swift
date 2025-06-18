import Foundation
import CoreAudio
import AVFAudio
import Combine

class AudioManager: ObservableObject {
    @Published var devices: [AudioDevice] = []
    @Published var activeDeviceID: String?
    
    private var lastTwoDeviceIDs: [String] = []
    private let propertyListenerQueue = DispatchQueue(label: "com.audioswitch.propertylistener")
    private var deviceShortcuts: [String: String] = [:] // DeviceID: Shortcut
    
    static let shared = AudioManager()
    
    init() {
        loadDeviceShortcuts()
        refreshDevices()
        setupPropertyListeners()
    }
    
    func refreshDevices() {
        var devices: [AudioDevice] = []
        
        // Get default output device first
        let defaultOutputID = getCurrentOutputDeviceID()
        
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
        
        guard status == noErr else { return }
        
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
        
        guard status == noErr else { return }
        
        for deviceID in audioDevices {
            if let device = createAudioDevice(from: deviceID, defaultID: defaultOutputID) {
                devices.append(device)
            }
        }
        
        DispatchQueue.main.async {
            // Apply saved shortcuts to devices
            for i in 0..<devices.count {
                devices[i].shortcut = self.deviceShortcuts[devices[i].id]
            }
            
            self.devices = devices.sorted { $0.name < $1.name }
            self.activeDeviceID = defaultOutputID
            
            // Update last two devices
            if let activeID = self.activeDeviceID {
                if !self.lastTwoDeviceIDs.contains(activeID) {
                    self.lastTwoDeviceIDs.insert(activeID, at: 0)
                    if self.lastTwoDeviceIDs.count > 2 {
                        self.lastTwoDeviceIDs.removeLast()
                    }
                }
            }
            
            // Update shortcuts in ShortcutManager
            self.updateShortcutRegistrations()
        }
    }
    
    private func createAudioDevice(from deviceID: AudioObjectID, defaultID: String?) -> AudioDevice? {
        // Check if it's an output device
        var streamAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &dataSize)
        guard status == noErr else { return nil }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }
        
        status = AudioObjectGetPropertyData(deviceID, &streamAddress, 0, nil, &dataSize, bufferList)
        guard status == noErr else { return nil }
        
        // Only include devices with output channels
        let channelCount = bufferList.pointee.mNumberBuffers
        guard channelCount > 0 else { return nil }
        
        // Get device UID
        let uid = getDeviceUID(deviceID) ?? String(deviceID)
        
        // Get device name
        let name = getDeviceName(deviceID) ?? "Unknown Device"
        
        // Get transport type
        let transportType = getDeviceTransportType(deviceID)
        
        return AudioDevice(
            id: uid,
            name: name,
            isOutput: true,
            transportType: transportType,
            isActive: uid == defaultID,
            shortcut: nil
        )
    }
    
    private func getDeviceUID(_ deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
        guard status == noErr else { return nil }
        
        var uid: CFString?
        let uidPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { uidPtr.deallocate() }
        status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, uidPtr)
        uid = uidPtr.pointee
        guard status == noErr, let uid = uid else { return nil }
        
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
    
    func switchToDevice(_ deviceID: String) {
        guard let audioObjectID = getAudioObjectID(from: deviceID) else { return }
        
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
            if !lastTwoDeviceIDs.contains(deviceID) {
                lastTwoDeviceIDs.insert(deviceID, at: 0)
                if lastTwoDeviceIDs.count > 2 {
                    lastTwoDeviceIDs.removeLast()
                }
            } else {
                // Move to front if already in list
                lastTwoDeviceIDs.removeAll { $0 == deviceID }
                lastTwoDeviceIDs.insert(deviceID, at: 0)
            }
            refreshDevices()
        }
    }
    
    func toggleBetweenLastTwo() {
        guard lastTwoDeviceIDs.count >= 2 else { return }
        
        if let currentID = activeDeviceID {
            let targetID = currentID == lastTwoDeviceIDs[0] ? lastTwoDeviceIDs[1] : lastTwoDeviceIDs[0]
            switchToDevice(targetID)
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
    
    func refreshShortcuts() {
        updateShortcutRegistrations()
    }
    
    private func updateShortcutRegistrations() {
        print("🔄 Updating shortcut registrations...")
        
        // Clear all existing shortcuts
        ShortcutManager.shared.clearAllShortcuts()
        
        // Register global toggle shortcut
        if let globalShortcut = UserDefaults.standard.globalShortcut {
            print("📝 Registering global toggle shortcut: \(globalShortcut)")
            ShortcutManager.shared.registerShortcut(globalShortcut, identifier: "global.toggle") {
                print("🔄 Global toggle shortcut triggered")
                self.toggleBetweenLastTwo()
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
}