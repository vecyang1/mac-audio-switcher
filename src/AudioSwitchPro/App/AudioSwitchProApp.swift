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
}