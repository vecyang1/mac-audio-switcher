import SwiftUI
import ServiceManagement
import AppKit
import UniformTypeIdentifiers

// Silent Mode App Model
struct SilentModeApp: Identifiable, Codable {
    let id: String // Bundle ID
    let name: String
    let path: String
    var isEnabled: Bool
}

struct SettingsView: View {
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false
    @AppStorage("startHiddenOnLogin") private var startHiddenOnLogin = false
    @AppStorage("globalShortcut") private var globalShortcut = ""
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = false
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @State private var enableGlobalShortcut = false
    @State private var isRecordingShortcut = false
    @State private var recordedKeys: [String] = []
    @State private var showingUpdateNotification = false
    @State private var silentModeApps: [SilentModeApp] = []
    @State private var selectedSilentApps: Set<String> = []
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
                            
                            Toggle("Start hidden on login", isOn: $startHiddenOnLogin)
                                .disabled(!autoStartEnabled)
                                .padding(.leading, 20)
                                .help("When enabled, the app will start in the background without showing the main window")
                            
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
                    
                    // Silent Mode Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Silent Mode")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // Description
                            VStack(alignment: .leading, spacing: 4) {
                                Text("If the current active app is in this list, AudioSwitch Pro will not respond to shortcuts.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    Text("Check the \"Disable Shortcuts\" to ignore shortcuts when using the app.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 8)
                            
                            // Apps List
                            VStack(spacing: 0) {
                                if silentModeApps.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary.opacity(0.3))
                                        Text("No apps in Silent Mode")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    // Header
                                    HStack {
                                        Text("App")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Disable Shortcuts")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    
                                    Divider()
                                    
                                    // App rows
                                    ForEach(silentModeApps) { app in
                                        silentModeAppRow(app: app)
                                        if app.id != silentModeApps.last?.id {
                                            Divider()
                                                .padding(.leading, 44)
                                        }
                                    }
                                }
                            }
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Controls
                            HStack {
                                Button(action: addSilentModeApp) {
                                    Image(systemName: "plus")
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: removeSilentModeApps) {
                                    Image(systemName: "minus")
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedSilentApps.isEmpty)
                                
                                Spacer()
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
                                    set: { 
                                        UserDefaults.standard.set($0, forKey: "showVirtualDevices")
                                        // Notify menu bar to rebuild
                                        NotificationCenter.default.post(name: Notification.Name("ShowVirtualDevicesChanged"), object: nil)
                                    }
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
                    
                    // License Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("License")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            LicenseStatusView()
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
        .frame(minWidth: 450, idealWidth: 450, maxWidth: 600, minHeight: 600, idealHeight: 800, maxHeight: 1000)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Initialize the toggle state based on whether a shortcut exists
            enableGlobalShortcut = !globalShortcut.isEmpty
            
            // Load silent mode apps
            loadSilentModeApps()
            
            // Start auto update check if enabled
            // if autoCheckForUpdates {
            //     UpdateService.shared.startAutoUpdateCheck()
            // }
        }
        // .sheet(isPresented: $showingUpdateNotification) {
        //     UpdateNotificationView()
        // }
    }
    
    // MARK: - Silent Mode Methods
    
    private func silentModeAppRow(app: SilentModeApp) -> some View {
        HStack {
            Button(action: {
                if selectedSilentApps.contains(app.id) {
                    selectedSilentApps.remove(app.id)
                } else {
                    selectedSilentApps.insert(app.id)
                }
            }) {
                HStack(spacing: 8) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                        Text(app.path)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { app.isEnabled },
                        set: { newValue in
                            toggleSilentModeApp(app.id, enabled: newValue)
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedSilentApps.contains(app.id) ? Color.accentColor.opacity(0.1) : Color.clear)
        }
    }
    
    private func addSilentModeApp() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Application"
        openPanel.message = "Choose an application to add to Silent Mode"
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [.application]
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        openPanel.begin { response in
            guard response == .OK else { return }
            
            for url in openPanel.urls {
                if let bundle = Bundle(url: url),
                   let bundleID = bundle.bundleIdentifier,
                   let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                    
                    let newApp = SilentModeApp(
                        id: bundleID,
                        name: appName,
                        path: url.path,
                        isEnabled: true
                    )
                    
                    // Avoid duplicates
                    if !silentModeApps.contains(where: { $0.id == bundleID }) {
                        silentModeApps.append(newApp)
                        saveSilentModeApps()
                    }
                }
            }
        }
    }
    
    private func removeSilentModeApps() {
        silentModeApps.removeAll { app in
            selectedSilentApps.contains(app.id)
        }
        selectedSilentApps.removeAll()
        saveSilentModeApps()
    }
    
    private func toggleSilentModeApp(_ appID: String, enabled: Bool) {
        if let index = silentModeApps.firstIndex(where: { $0.id == appID }) {
            silentModeApps[index].isEnabled = enabled
            saveSilentModeApps()
        }
    }
    
    private func loadSilentModeApps() {
        if let data = UserDefaults.standard.data(forKey: "silentModeApps"),
           let apps = try? JSONDecoder().decode([SilentModeApp].self, from: data) {
            silentModeApps = apps
        }
    }
    
    private func saveSilentModeApps() {
        if let data = try? JSONEncoder().encode(silentModeApps) {
            UserDefaults.standard.set(data, forKey: "silentModeApps")
        }
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
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1"
    }
}

#Preview {
    SettingsView()
}