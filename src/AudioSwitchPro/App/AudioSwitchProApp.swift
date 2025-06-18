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
        
        // Always show the main window on first launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showMainWindow()
        }
    }
    
    private func showMainWindow() {
        // Find and show the main window
        if let window = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "AudioSwitch Pro" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in background when window closed
    }
    
    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Show both speaker and mic icons
            let attributedString = NSMutableAttributedString()
            
            // Speaker icon
            let speakerAttachment = NSTextAttachment()
            speakerAttachment.image = NSImage(systemSymbolName: "speaker.wave.2", accessibilityDescription: "Output")
            speakerAttachment.image?.size = NSSize(width: 16, height: 16)
            speakerAttachment.image?.isTemplate = true
            attributedString.append(NSAttributedString(attachment: speakerAttachment))
            
            // Mic icon
            let micAttachment = NSTextAttachment()
            micAttachment.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Input")
            micAttachment.image?.size = NSSize(width: 16, height: 16)
            micAttachment.image?.isTemplate = true
            attributedString.append(NSAttributedString(attachment: micAttachment))
            
            button.attributedTitle = attributedString
            button.action = #selector(menuBarIconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create the menu
        setupMenuBarMenu()
    }
    
    private func setupMenuBarMenu() {
        let menu = NSMenu()
        
        // Add current output device header
        let currentOutputDevice = AudioManager.shared.outputDevices.first { $0.isActive }
        if let device = currentOutputDevice {
            let headerItem = NSMenuItem(title: "Output: \(device.name)", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            let headerFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            headerItem.attributedTitle = NSAttributedString(string: "Output: \(device.name)", 
                                                          attributes: [.font: headerFont])
            menu.addItem(headerItem)
        }
        
        // Add audio output devices
        let outputDevices = AudioManager.shared.outputDevices
        if !outputDevices.isEmpty {
            for device in outputDevices {
                let title = device.isOnline ? device.name : "\(device.name) (Offline)"
                let item = NSMenuItem(title: title, action: #selector(switchToDevice(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = device
                // Enable all devices for clicking, including Bluetooth devices that might be available for connection
                item.isEnabled = true
                if device.isActive {
                    item.state = .on
                }
                // Add shortcut if available
                if let shortcut = device.shortcut {
                    item.keyEquivalent = ""
                    item.keyEquivalentModifierMask = []
                    item.title = "\(title) \(shortcut)"
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
        
        // Add current input device header
        let currentInputDevice = AudioManager.shared.inputDevices.first { $0.isActive }
        if let device = currentInputDevice {
            let headerItem = NSMenuItem(title: "Input: \(device.name)", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            let headerFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            headerItem.attributedTitle = NSAttributedString(string: "Input: \(device.name)", 
                                                          attributes: [.font: headerFont])
            menu.addItem(headerItem)
        }
        
        // Add audio input devices
        let inputDevices = AudioManager.shared.inputDevices
        if !inputDevices.isEmpty {
            for device in inputDevices {
                let title = device.isOnline ? device.name : "\(device.name) (Offline)"
                let item = NSMenuItem(title: title, action: #selector(switchToDevice(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = device
                item.isEnabled = true
                if device.isActive {
                    item.state = .on
                }
                // Add shortcut if available
                if let shortcut = device.shortcut {
                    item.keyEquivalent = ""
                    item.keyEquivalentModifierMask = []
                    item.title = "\(title) \(shortcut)"
                }
                // Add mic icon
                if let image = NSImage(systemSymbolName: "mic", accessibilityDescription: nil) {
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
        showMainWindow()
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