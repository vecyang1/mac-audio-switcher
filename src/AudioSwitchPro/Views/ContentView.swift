import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var showSettings = false
    @State private var hoveredDeviceID: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(showSettings: $showSettings)
                .padding()
            
            Divider()
            
            // Error Banner (if any) - temporarily disabled for build
            // if !audioManager.isHealthy, let error = audioManager.lastError {
            //     ErrorBannerView(error: error) {
            //         // Retry action
            //         audioManager.refreshDevices()
            //     }
            //     .padding(.horizontal)
            //     .padding(.top, 8)
            // }
            
            // Device List
            ScrollView {
                VStack(spacing: 0) {
                    // Output Devices Section
                    SectionHeaderView(title: "OUTPUT DEVICES")
                    
                    VStack(spacing: 8) {
                        ForEach(audioManager.outputDevices.filter { !$0.isHidden }) { device in
                            DeviceRowView(
                                device: device,
                                isHovered: hoveredDeviceID == device.id,
                                onSwitchDevice: {
                                    audioManager.setDevice(device)
                                    
                                    // Keep the window visible and focused after switching
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let window = NSApp.windows.first {
                                            window.makeKeyAndOrderFront(nil)
                                        }
                                    }
                                },
                                onSetShortcut: { shortcut in
                                    audioManager.setShortcut(shortcut, for: device.id)
                                },
                                onClearShortcut: {
                                    audioManager.clearShortcut(for: device.id)
                                }
                            )
                            .onHover { isHovered in
                                hoveredDeviceID = isHovered ? device.id : nil
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Input Devices Section
                    SectionHeaderView(title: "INPUT DEVICES")
                    
                    VStack(spacing: 8) {
                        ForEach(audioManager.inputDevices.filter { !$0.isHidden }) { device in
                            DeviceRowView(
                                device: device,
                                isHovered: hoveredDeviceID == device.id,
                                showInputLevel: true,
                                onSwitchDevice: {
                                    audioManager.setDevice(device)
                                    
                                    // Keep the window visible and focused after switching
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let window = NSApp.windows.first {
                                            window.makeKeyAndOrderFront(nil)
                                        }
                                    }
                                },
                                onSetShortcut: { shortcut in
                                    audioManager.setShortcut(shortcut, for: device.id)
                                },
                                onClearShortcut: {
                                    audioManager.clearShortcut(for: device.id)
                                }
                            )
                            .onHover { isHovered in
                                hoveredDeviceID = isHovered ? device.id : nil
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            
            Divider()
            
            // Footer
            FooterView()
                .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            // Start monitoring when window appears
            audioManager.startInputMonitoring()
        }
        .onDisappear {
            // Stop monitoring when window disappears
            audioManager.stopInputMonitoring()
        }
    }
}

struct HeaderView: View {
    @Binding var showSettings: Bool
    @AppStorage("globalShortcut") private var globalShortcut = ""
    @AppStorage("enableGlobalShortcut") private var enableGlobalShortcut = false
    @State private var isRecordingShortcut = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AudioSwitch Pro")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Click to switch • Right-click for shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Global Panel Shortcut Display
            if enableGlobalShortcut {
                Button(action: startRecordingShortcut) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Panel Toggle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(isRecordingShortcut ? "Press keys..." : (globalShortcut.isEmpty ? "Set Shortcut" : globalShortcut))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isRecordingShortcut ? Color.accentColor : Color.accentColor.opacity(0.2))
                            .foregroundColor(isRecordingShortcut ? .white : .primary)
                            .cornerRadius(4)
                    }
                    .help(isRecordingShortcut ? "Press keys to set shortcut" : "Click to change shortcut")
                }
                .buttonStyle(.plain)
            }
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func startRecordingShortcut() {
        isRecordingShortcut = true
        
        // Remove any existing monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Set up event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if self.isRecordingShortcut {
                self.handleKeyEvent(event)
                return nil // Consume the event
            }
            return event
        }
        
        // Auto-cancel after 10 seconds - clear shortcut on timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isRecordingShortcut {
                self.globalShortcut = ""
                AudioManager.shared.refreshShortcuts()
                self.stopRecording()
            }
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Only handle keyDown events
        guard event.type == .keyDown else { return }
        
        // ESC to cancel - clear the shortcut
        if event.keyCode == 53 { // ESC key
            globalShortcut = ""
            AudioManager.shared.refreshShortcuts()
            stopRecording()
            return
        }
        
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
        
        // Require at least one modifier key
        if keys.count >= 2 {
            let shortcut = keys.joined()
            globalShortcut = shortcut
            AudioManager.shared.refreshShortcuts()
            stopRecording()
        }
    }
    
    private func stopRecording() {
        isRecordingShortcut = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.separatorColor).opacity(0.1))
    }
}

struct FooterView: View {
    @AppStorage("globalShortcut") private var shortcut = ""
    
    var body: some View {
        HStack {
            if !shortcut.isEmpty {
                HStack(spacing: 4) {
                    Label("Show Panel", systemImage: "keyboard")
                    Text(shortcut)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text("Set shortcuts: Click button OR right-click device")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 380, height: 480)
}