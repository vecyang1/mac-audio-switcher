import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false
    @AppStorage("globalShortcut") private var globalShortcut = ""
    @State private var enableGlobalShortcut = false
    @State private var isRecordingShortcut = false
    @State private var recordedKeys: [String] = []
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Launch at login", isOn: $autoStartEnabled)
                                .onChange(of: autoStartEnabled) { newValue in
                                    configureAutoStart(newValue)
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
                                Toggle("Enable global shortcut to show/hide panel", isOn: $enableGlobalShortcut)
                                    .onChange(of: enableGlobalShortcut) { newValue in
                                        if !newValue {
                                            globalShortcut = ""
                                            AudioManager.shared.refreshShortcuts()
                                        }
                                    }
                                
                                if enableGlobalShortcut {
                                    HStack {
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
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                        }
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
                                Text("1.0")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Developer")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Link("Vec Yang", destination: URL(string: "https://github.com/vecyang1")!)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Source Code")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Link("GitHub", destination: URL(string: "https://github.com/vecyang1/mac-audio-switcher")!)
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
        .frame(width: 500, height: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Initialize the toggle state based on whether a shortcut exists
            enableGlobalShortcut = !globalShortcut.isEmpty
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
}

#Preview {
    SettingsView()
}