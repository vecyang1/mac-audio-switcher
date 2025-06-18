import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false
    @AppStorage("globalShortcut") private var globalShortcut = "⌘⌥A"
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
            }
            .padding()
            
            Divider()
            
            // Settings Content
            Form {
                Section {
                    Toggle("Launch at login", isOn: $autoStartEnabled)
                        .onChange(of: autoStartEnabled) { newValue in
                            configureAutoStart(newValue)
                        }
                } header: {
                    Text("General")
                        .font(.headline)
                }
                
                Section {
                    HStack {
                        Text("Toggle shortcut")
                        
                        Spacer()
                        
                        Button(action: startRecordingShortcut) {
                            Text(isRecordingShortcut ? "Press keys..." : globalShortcut)
                                .frame(minWidth: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isRecordingShortcut ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundColor(isRecordingShortcut ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Use this shortcut to quickly toggle between your last two audio devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AudioSwitch Pro v1.0")
                            .font(.body)
                        
                        Link("View on GitHub", destination: URL(string: "https://github.com/vecyang1/mac-audio-switcher")!)
                            .font(.caption)
                        
                        Text("Made with ❤️ for the Mac community")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                        .font(.headline)
                }
            }
            // .formStyle(.grouped) // Available in macOS 13+
            // .scrollContentBackground(.hidden) // Available in macOS 13+
        }
        .frame(width: 450, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func startRecordingShortcut() {
        isRecordingShortcut = true
        recordedKeys = []
        
        // Set up event monitor
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if self.isRecordingShortcut {
                self.handleKeyEvent(event)
                return nil
            }
            return event
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
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
        
        // Add the key if it's not just a modifier
        if event.type == .keyDown {
            if let characters = event.charactersIgnoringModifiers?.uppercased() {
                keys.append(characters)
            }
            
            // Save the shortcut
            if !keys.isEmpty {
                let shortcut = keys.joined()
                globalShortcut = shortcut
                isRecordingShortcut = false
                
                // Update the shortcut manager
                ShortcutManager.shared.updateShortcut(shortcut)
            }
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