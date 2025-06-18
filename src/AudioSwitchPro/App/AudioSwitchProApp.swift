import SwiftUI

@main
struct AudioSwitchProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, idealWidth: 450, minHeight: 500, idealHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        //.windowResizability(.contentSize) // Available in macOS 13+
        
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure dock icon is visible (normal app behavior)
        NSApp.setActivationPolicy(.regular)
        
        // Check system compatibility - temporarily disabled for build
        // let systemInfo = SystemCompatibility.shared.checkSystemCompatibility()
        // print("🔍 System Compatibility: \(systemInfo.compatibilityLevel)")
        
        // if !systemInfo.isSupported {
        //     DispatchQueue.main.async {
        //         self.showCompatibilityAlert(systemInfo)
        //     }
        //     return
        // }
        
        // Log warnings if any
        // if !systemInfo.warnings.isEmpty {
        //     print("⚠️ System warnings: \(systemInfo.warnings.joined(separator: ", "))")
        // }
        
        // Set up auto-start if enabled
        if UserDefaults.standard.autoStartEnabled {
            // Auto-start logic will be implemented here
        }
        
        // Initialize shortcut manager
        ShortcutManager.shared.setupShortcuts()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background when window closed
    }
    
    // private func showCompatibilityAlert(_ systemInfo: SystemCompatibility.SystemInfo) {
    //     let alert = NSAlert()
    //     alert.messageText = "System Compatibility Issue"
    //     alert.informativeText = """
    //     AudioSwitch Pro requires macOS 12.0 or later.
    //     
    //     Current system: macOS \(systemInfo.macOSVersion)
    //     Architecture: \(systemInfo.architecture)
    //     
    //     Please update your macOS to use this application.
    //     """
    //     alert.alertStyle = .warning
    //     alert.addButton(withTitle: "Quit")
    //     alert.addButton(withTitle: "Continue Anyway")
    //     
    //     let response = alert.runModal()
    //     if response == .alertFirstButtonReturn {
    //         NSApplication.shared.terminate(nil)
    //     }
    // }
}