#!/usr/bin/env swift

// Test script for Silent Mode functionality
// Run with: swift test-silent-mode.swift

import Foundation
import AppKit

// Mock SilentModeApp structure
struct SilentModeApp: Codable {
    let id: String
    let name: String
    let path: String
    var isEnabled: Bool
}

// Test UserDefaults extension
extension UserDefaults {
    private static let silentModeAppsKey = "silentModeApps"
    
    var silentModeApps: [SilentModeApp] {
        get {
            guard let data = data(forKey: Self.silentModeAppsKey),
                  let apps = try? JSONDecoder().decode([SilentModeApp].self, from: data) else {
                return []
            }
            return apps
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.silentModeAppsKey)
            }
        }
    }
}

// Test functions
func testSilentModeApp() {
    print("🧪 Testing SilentModeApp creation...")
    
    let app = SilentModeApp(
        id: "com.apple.dt.Xcode",
        name: "Xcode",
        path: "/Applications/Xcode.app",
        isEnabled: true
    )
    
    print("✅ Created app: \(app.name) (\(app.id))")
}

func testUserDefaultsPersistence() {
    print("\n🧪 Testing UserDefaults persistence...")
    
    let testApps = [
        SilentModeApp(id: "com.notion.id", name: "Notion", path: "/Applications/Notion.app", isEnabled: true),
        SilentModeApp(id: "com.apple.FinalCut", name: "Final Cut Pro", path: "/Applications/Final Cut Pro.app", isEnabled: false)
    ]
    
    // Save
    UserDefaults.standard.silentModeApps = testApps
    print("✅ Saved \(testApps.count) apps")
    
    // Load
    let loadedApps = UserDefaults.standard.silentModeApps
    print("✅ Loaded \(loadedApps.count) apps")
    
    for app in loadedApps {
        print("  - \(app.name): \(app.isEnabled ? "Enabled" : "Disabled")")
    }
}

func testActiveAppDetection() {
    print("\n🧪 Testing active app detection...")
    
    if let activeApp = NSWorkspace.shared.frontmostApplication {
        print("✅ Current active app: \(activeApp.localizedName ?? "Unknown")")
        print("  Bundle ID: \(activeApp.bundleIdentifier ?? "Unknown")")
    }
}

func testAppFromURL() {
    print("\n🧪 Testing app creation from URL...")
    
    let appPaths = [
        "/Applications/Safari.app",
        "/Applications/Xcode.app",
        "/System/Applications/Music.app"
    ]
    
    for path in appPaths {
        let url = URL(fileURLWithPath: path)
        if let bundle = Bundle(url: url),
           let bundleID = bundle.bundleIdentifier,
           let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            print("✅ \(appName) - \(bundleID)")
        }
    }
}

// Run tests
print("🚀 Silent Mode Test Suite\n")
testSilentModeApp()
testUserDefaultsPersistence()
testActiveAppDetection()
testAppFromURL()
print("\n✨ All tests completed!")

// Clean up test data
UserDefaults.standard.removeObject(forKey: "silentModeApps")
print("🧹 Cleaned up test data")