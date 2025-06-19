import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false
    @AppStorage("globalShortcut") private var globalShortcut = ""
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = false
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @State private var enableGlobalShortcut = false
    @State private var isRecordingShortcut = false
    @State private var recordedKeys: [String] = []
    @State private var showingUpdateNotification = false
    // @StateObject private var updateService = UpdateService.shared // TODO: Add to Xcode project
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            
            Divider()
            
            // Settings Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // General Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Launch at login", isOn: $autoStartEnabled)
                                .onChange(of: autoStartEnabled) { newValue in
                                    configureAutoStart(newValue)
                                }
                            
                            Divider()
                            
                            Toggle("Show icon in Dock", isOn: $showDockIcon)
                                .onChange(of: showDockIcon) { newValue in
                                    updateDockIconVisibility(newValue)
                                }
                            
                            if !showDockIcon && !showMenuBarIcon {
                                Label("Enable menu bar icon to access the app when dock icon is hidden", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 4)
                            }
                            
                            Toggle("Show icon in menu bar", isOn: $showMenuBarIcon)
                                .onChange(of: showMenuBarIcon) { newValue in
                                    updateMenuBarIcon(newValue)
                                }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Keyboard Shortcuts Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Global Panel Shortcut")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Enable/Disable Global Shortcut
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Toggle("", isOn: $enableGlobalShortcut)
                                        .onChange(of: enableGlobalShortcut) { newValue in
                                            if !newValue {
                                                globalShortcut = ""
                                                AudioManager.shared.refreshShortcuts()
                                            }
                                        }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Panel Toggle Shortcut")
                                            .font(.body)
                                        Text("Show/hide AudioSwitch Pro from anywhere")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: startRecordingShortcut) {
                                        Text(isRecordingShortcut ? "Press keys..." : (globalShortcut.isEmpty ? "Set Shortcut" : globalShortcut))
                                            .frame(minWidth: 100)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(isRecordingShortcut ? Color.accentColor : Color(NSColor.controlColor))
                                            .foregroundColor(isRecordingShortcut ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!enableGlobalShortcut)
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Hidden Devices Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Hidden Devices")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            let hiddenDevices = AudioManager.shared.getHiddenDevices()
                            
                            if hiddenDevices.isEmpty {
                                HStack {
                                    Image(systemName: "eye.slash")
                                        .font(.title2)
                                        .foregroundColor(.secondary.opacity(0.5))
                                    VStack(alignment: .leading) {
                                        Text("No hidden devices")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        Text("Right-click any device and select \"Hide Device\"")
                                            .font(.caption)
                                            .foregroundColor(.secondary.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            } else {
                                ForEach(hiddenDevices) { device in
                                    HStack {
                                        Image(systemName: device.transportType.icon)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(device.name)
                                                .font(.body)
                                            Text("\(device.isOutput ? "Output" : "Input") • \(device.transportType.rawValue)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Show") {
                                            AudioManager.shared.unhideDevice(device.id)
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if device.id != hiddenDevices.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Virtual Devices Section (placed after Hidden Devices to discourage use)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Virtual Devices")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Toggle("", isOn: .init(
                                    get: { UserDefaults.standard.bool(forKey: "showVirtualDevices") },
                                    set: { UserDefaults.standard.set($0, forKey: "showVirtualDevices") }
                                ))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Show Virtual Audio Devices")
                                        .font(.body)
                                    Text("Enable switching to virtual devices like Loopback Audio (may cause crashes)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            if UserDefaults.standard.bool(forKey: "showVirtualDevices") {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Warning: Virtual devices may cause the app to crash. If this happens, the app will automatically reset to built-in devices on next launch.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // Updates Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Updates")
                                .font(.headline)
                            
                            Spacer()
                            
                            // UpdateBadgeView() // TODO: Add UpdateNotificationView to project
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Check for updates automatically", isOn: $autoCheckForUpdates)
                                .onChange(of: autoCheckForUpdates) { newValue in
                                    // if newValue {
                                    //     UpdateService.shared.startAutoUpdateCheck()
                                    // } else {
                                    //     UpdateService.shared.stopAutoUpdateCheck()
                                    // }
                                    print("Auto update check: \(newValue)")
                                }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Version: \(getAppVersion())")
                                        .font(.body)
                                    // if UpdateService.shared.updateAvailable {
                                    //     Text("Latest Version: \(UpdateService.shared.latestVersion ?? "")")
                                    //     .font(.caption)
                                    //     .foregroundColor(.secondary)
                                    // }
                                }
                                
                                Spacer()
                                
                                Button("Check Now") {
                                    // UpdateService.shared.checkForUpdates { available in
                                    //     if available {
                                    //         showingUpdateNotification = true
                                    //     }
                                    // }
                                    print("Update check will be available after adding UpdateService to project")
                                }
                                // .disabled(UpdateService.shared.isChecking)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(getAppVersion())
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Developer")
                                    .foregroundColor(.secondary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Vec")
                                        .font(.body)
                                    Link("viviscallers@gmail.com", destination: URL(string: "mailto:viviscallers@gmail.com")!)
                                        .font(.caption)
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Project")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Link("GitHub", destination: URL(string: "https://github.com/vecyang1")!)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Initialize the toggle state based on whether a shortcut exists
            enableGlobalShortcut = !globalShortcut.isEmpty
            
            // Start auto update check if enabled
            // if autoCheckForUpdates {
            //     UpdateService.shared.startAutoUpdateCheck()
            // }
        }
        // .sheet(isPresented: $showingUpdateNotification) {
        //     UpdateNotificationView()
        // }
    }
    
    @State private var settingsEventMonitor: Any?
    
    private func startRecordingShortcut() {
        isRecordingShortcut = true
        recordedKeys = []
        
        // Remove any existing monitor
        if let monitor = settingsEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Set up event monitor
        settingsEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if self.isRecordingShortcut {
                self.handleKeyEvent(event)
                return nil
            }
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Only handle keyDown events
        guard event.type == .keyDown else { return }
        
        var keys: [String] = []
        
        // Check modifiers
        if event.modifierFlags.contains(.command) {
            keys.append("⌘")
        }
        if event.modifierFlags.contains(.option) {
            keys.append("⌥")
        }
        if event.modifierFlags.contains(.control) {
            keys.append("⌃")
        }
        if event.modifierFlags.contains(.shift) {
            keys.append("⇧")
        }
        
        // Add the main key
        if let characters = event.charactersIgnoringModifiers?.uppercased() {
            keys.append(characters)
        }
        
        // Require at least one modifier and one key
        if keys.count >= 2 {
            let shortcut = keys.joined()
            globalShortcut = shortcut
            
            // Stop recording
            stopRecordingShortcut()
            
            // Update the shortcut manager
            ShortcutManager.shared.updateShortcut(shortcut)
            print("🎯 Updated global shortcut to: \(shortcut)")
        }
    }
    
    private func stopRecordingShortcut() {
        isRecordingShortcut = false
        
        if let monitor = settingsEventMonitor {
            NSEvent.removeMonitor(monitor)
            settingsEventMonitor = nil
        }
    }
    
    private func configureAutoStart(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to configure auto-start: \(error)")
            }
        }
    }
    
    private func updateDockIconVisibility(_ show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            // When hiding dock icon, ensure menu bar icon is enabled
            if !showMenuBarIcon {
                showMenuBarIcon = true
                updateMenuBarIcon(true)
            }
            
            // Get current main window state before switching activation policy
            let mainWindow = NSApp.windows.first(where: { $0.title.isEmpty || $0.title == "AudioSwitch Pro" })
            let wasVisible = mainWindow?.isVisible ?? false
            
            NSApp.setActivationPolicy(.accessory)
            
            // If the main window was visible, keep it visible after switching to accessory mode
            if wasVisible, let window = mainWindow {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    window.makeKeyAndOrderFront(nil)
                    // For accessory apps, we need to explicitly activate to show windows
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }
    
    private func updateMenuBarIcon(_ show: Bool) {
        // This will be handled by AudioManager
        NotificationCenter.default.post(name: Notification.Name("UpdateMenuBarIcon"), 
                                      object: nil, 
                                      userInfo: ["show": show])
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0"
    }
}

#Preview {
    SettingsView()
}