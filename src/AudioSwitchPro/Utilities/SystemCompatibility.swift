import Foundation
import AppKit
import os.log
import CoreAudio
import AVFAudio
import IOKit

class SystemCompatibility {
    static let shared = SystemCompatibility()
    private let logger = Logger(subsystem: "com.vecyang.AudioSwitchPro", category: "SystemCompatibility")
    
    private init() {}
    
    struct SystemInfo {
        let macOSVersion: String
        let isSupported: Bool
        let architecture: String
        let modelIdentifier: String
        let warnings: [String]
        let recommendations: [String]
    }
    
    func checkSystemCompatibility() -> SystemInfo {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        
        // Check minimum macOS version (12.0+)
        let isSupported = osVersion.majorVersion >= 12
        
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Architecture detection
        let architecture = getArchitecture()
        
        // Model identification
        let modelId = getModelIdentifier()
        
        // Version-specific checks
        if osVersion.majorVersion < 12 {
            warnings.append("macOS 12.0 or later required")
            recommendations.append("Please update your macOS to version 12.0 or later")
        } else if osVersion.majorVersion == 12 && osVersion.minorVersion < 3 {
            warnings.append("Some features may not work optimally on macOS 12.0-12.2")
            recommendations.append("Consider updating to macOS 12.3 or later for best experience")
        }
        
        // Architecture-specific recommendations
        if architecture == "x86_64" {
            recommendations.append("Running on Intel Mac - performance may vary")
        } else if architecture == "arm64" {
            logger.info("✅ Running on Apple Silicon - optimal performance expected")
        }
        
        // Audio system availability check
        if !checkAudioSystemAvailability() {
            warnings.append("Audio system may not be fully available")
            recommendations.append("Restart the app or check audio system preferences")
        }
        
        logger.info("🔍 System Info: macOS \(versionString), \(architecture), \(modelId)")
        
        return SystemInfo(
            macOSVersion: versionString,
            isSupported: isSupported,
            architecture: architecture,
            modelIdentifier: modelId,
            warnings: warnings,
            recommendations: recommendations
        )
    }
    
    private func getArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let architecture = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
        
        // Normalize architecture names
        switch architecture {
        case "arm64":
            return "arm64"
        case "x86_64":
            return "x86_64"
        default:
            return architecture
        }
    }
    
    private func getModelIdentifier() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        
        var modelIdentifier: String = "Unknown"
        
        if let modelData = IORegistryEntryCreateCFProperty(service,
                                                           "model" as CFString,
                                                           kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? "Unknown"
        }
        
        IOObjectRelease(service)
        return modelIdentifier
    }
    
    private func checkAudioSystemAvailability() -> Bool {
        // Basic check for Core Audio availability
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyRunLoop,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        return status == noErr
    }
    
    func checkPermissions() -> [String] {
        var missingPermissions: [String] = []
        
        // Check microphone access (for audio input)
        switch AVAudioSession.sharedInstance().recordPermission {
        case .denied:
            missingPermissions.append("Microphone access denied")
        case .undetermined:
            missingPermissions.append("Microphone access not determined")
        case .granted:
            break
        @unknown default:
            missingPermissions.append("Unknown microphone permission state")
        }
        
        return missingPermissions
    }
    
    func getSystemRecommendations() -> [String] {
        var recommendations: [String] = []
        let sysInfo = checkSystemCompatibility()
        
        if !sysInfo.isSupported {
            recommendations.append("Upgrade to macOS 12.0 or later")
        }
        
        if sysInfo.architecture == "x86_64" {
            recommendations.append("For best performance, consider upgrading to Apple Silicon Mac")
        }
        
        let permissions = checkPermissions()
        if !permissions.isEmpty {
            recommendations.append("Grant required permissions in System Preferences")
        }
        
        return recommendations
    }
}

// Extension for easy access
extension SystemCompatibility.SystemInfo {
    var isOptimal: Bool {
        return isSupported && warnings.isEmpty
    }
    
    var compatibilityLevel: String {
        if !isSupported {
            return "Unsupported"
        } else if !warnings.isEmpty {
            return "Limited"
        } else {
            return "Full"
        }
    }
}