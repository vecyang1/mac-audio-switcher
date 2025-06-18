import SwiftUI

@main
struct AudioSwitchProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, idealWidth: 460, minHeight: 450, idealHeight: 520)
                .onAppear {
                    restoreWindowSize()
                }
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
        }
    }
    
    private func restoreWindowSize() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                // Restore saved window frame if available
                if let frameString = UserDefaults.standard.string(forKey: "MainWindowFrame"),
                   let frame = NSRectFromString(frameString) as NSRect? {
                    window.setFrame(frame, display: true)
                } else {
                    // Set default size (less rectangular)
                    let frame = NSRect(x: window.frame.origin.x, 
                                     y: window.frame.origin.y, 
                                     width: 460, 
                                     height: 520)
                    window.setFrame(frame, display: true)
                    window.center()
                }
                
                // Set up window frame autosave
                window.setFrameAutosaveName("MainWindow")
                
                // Save frame on resize
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "MainWindowFrame")
                }
                
                // Save frame on move
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "MainWindowFrame")
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set dock icon visibility based on user preference
        let showDockIcon = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
        
        // Set up menu bar icon if enabled
        let showMenuBarIcon = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        if showMenuBarIcon {
            setupMenuBarIcon()
        }
        
        // Listen for menu bar updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuBarIcon(_:)),
            name: Notification.Name("UpdateMenuBarIcon"),
            object: nil
        )
        
        // Listen for device changes to update menu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioDevicesChanged(_:)),
            name: Notification.Name("AudioDevicesChanged"),
            object: nil
        )
        
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
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Create a custom menu bar icon with better visibility
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            
            if let image = NSImage(systemSymbolName: "speaker.wave.2.circle.fill", accessibilityDescription: "AudioSwitch Pro")?.withSymbolConfiguration(config) {
                button.image = image
                button.image?.size = NSSize(width: 18, height: 18)
                button.image?.isTemplate = true
            } else if let image = NSImage(named: "MenuBarIcon") {
                // Fallback to asset icon
                button.image = image
                button.image?.size = NSSize(width: 18, height: 18)
                button.image?.isTemplate = true
            }
            
            button.action = #selector(menuBarIconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create the menu
        setupMenuBarMenu()
    }
    
    private func setupMenuBarMenu() {
        let menu = NSMenu()
        
        // Add current device header
        let currentDevice = AudioManager.shared.outputDevices.first { $0.isActive }
        if let device = currentDevice {
            let headerItem = NSMenuItem(title: "Current: \(device.name)", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            let headerFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            headerItem.attributedTitle = NSAttributedString(string: "Current: \(device.name)", 
                                                          attributes: [.font: headerFont])
            menu.addItem(headerItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add audio output devices
        let outputDevices = AudioManager.shared.outputDevices
        if !outputDevices.isEmpty {
            for device in outputDevices {
                let title = device.isOnline ? device.name : "\(device.name) (Offline)"
                let item = NSMenuItem(title: title, action: device.isOnline ? #selector(switchToDevice(_:)) : nil, keyEquivalent: "")
                item.target = self
                item.representedObject = device
                item.isEnabled = device.isOnline
                if device.isActive {
                    item.state = .on
                }
                // Add transport type icon
                if let image = NSImage(systemSymbolName: device.transportType.icon, accessibilityDescription: nil) {
                    image.size = NSSize(width: 16, height: 16)
                    item.image = image
                }
                menu.addItem(item)
            }
            
            menu.addItem(NSMenuItem.separator())
        }
        
        // Show Main Panel
        let showPanelItem = NSMenuItem(title: "Show Main Panel", action: #selector(showMainPanel), keyEquivalent: "")
        showPanelItem.target = self
        menu.addItem(showPanelItem)
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit AudioSwitch Pro", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func menuBarIconClicked() {
        // Always show the menu on click (both left and right)
        statusItem?.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc private func switchToDevice(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioDevice else { return }
        AudioManager.shared.setDevice(device)
        
        // Update menu item states
        if let menu = statusItem?.menu {
            for item in menu.items {
                if let itemDevice = item.representedObject as? AudioDevice {
                    item.state = itemDevice.id == device.id ? .on : .off
                }
            }
        }
    }
    
    @objc private func showMainPanel() {
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func updateMenuBarIcon(_ notification: Notification) {
        if let show = notification.userInfo?["show"] as? Bool {
            if show {
                if statusItem == nil {
                    setupMenuBarIcon()
                }
            } else {
                if statusItem != nil {
                    NSStatusBar.system.removeStatusItem(statusItem!)
                    statusItem = nil
                }
            }
        }
    }
    
    @objc private func audioDevicesChanged(_ notification: Notification) {
        // Update the menu when devices change
        setupMenuBarMenu()
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