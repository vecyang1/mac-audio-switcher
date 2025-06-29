import Foundation
import AppKit

struct SilentModeApp: Identifiable, Codable, Equatable {
    let id: String // Bundle identifier
    let name: String
    let path: String
    var isEnabled: Bool
    
    init(id: String, name: String, path: String, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.path = path
        self.isEnabled = isEnabled
    }
    
    static func == (lhs: SilentModeApp, rhs: SilentModeApp) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SilentModeApp {
    static func fromURL(_ url: URL) -> SilentModeApp? {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String else {
            return nil
        }
        
        return SilentModeApp(
            id: bundleIdentifier,
            name: appName,
            path: url.path,
            isEnabled: true
        )
    }
    
    var icon: NSImage? {
        return NSWorkspace.shared.icon(forFile: path)
    }
}

// UserDefaults extension for silent mode apps
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