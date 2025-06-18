import SwiftUI

struct DeviceRowView: View {
    let device: AudioDevice
    let isHovered: Bool
    let onSwitchDevice: () -> Void
    let onSetShortcut: (String) -> Void
    let onClearShortcut: () -> Void
    
    @State private var isRecordingShortcut = false
    @State private var eventMonitor: Any?
    
    private var backgroundColor: Color {
        if device.isActive {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Active Indicator (moved to left)
            if device.isActive {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.body)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                    // .symbolEffect(.variableColor.iterative, isActive: device.isActive) // Available in macOS 14+
            } else {
                // Empty space for alignment when not active
                Color.clear
                    .frame(width: 20)
            }
            
            // Device Icon
            Image(systemName: device.transportType.icon)
                .font(.title2)
                .foregroundColor(device.isActive ? .accentColor : .secondary)
                .frame(width: 32)
            
            // Device Info
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.body)
                    .fontWeight(device.isActive ? .medium : .regular)
                    .foregroundColor(device.isOnline ? (device.isActive ? .primary : .primary.opacity(0.9)) : .secondary)
                
                HStack(spacing: 8) {
                    Text(device.transportType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !device.isOnline {
                        Label("Offline", systemImage: "circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if device.isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            Spacer()
            
            // Shortcut Section
            HStack(spacing: 8) {
                if let shortcut = device.shortcut {
                    // Display existing shortcut
                    HStack(spacing: 4) {
                        Text(shortcut)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                        
                        Button(action: onClearShortcut) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Clear shortcut")
                    }
                } else {
                    // Set shortcut button
                    Button(action: startRecordingShortcut) {
                        Text(isRecordingShortcut ? "Press keys..." : "Set Shortcut")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isRecordingShortcut ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundColor(isRecordingShortcut ? .white : .primary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Click to assign a keyboard shortcut")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(device.isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: device.isActive)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle()) // Make entire row clickable
        .onTapGesture {
            if !isRecordingShortcut && device.isOnline {
                onSwitchDevice()
            }
        }
        .contextMenu {
            DeviceContextMenu(
                device: device,
                onSwitchDevice: onSwitchDevice,
                onSetShortcut: onSetShortcut,
                onClearShortcut: onClearShortcut,
                onStartRecording: startRecordingShortcut
            )
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
        
        // Auto-cancel after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isRecordingShortcut {
                self.stopRecording()
            }
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Only handle keyDown events
        guard event.type == .keyDown else { return }
        
        // ESC to cancel
        if event.keyCode == 53 { // ESC key
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
            onSetShortcut(shortcut)
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

struct DeviceContextMenu: View {
    let device: AudioDevice
    let onSwitchDevice: () -> Void
    let onSetShortcut: (String) -> Void
    let onClearShortcut: () -> Void
    let onStartRecording: () -> Void
    
    @State private var isRecordingShortcut = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        Group {
            // Primary action
            Button(action: onSwitchDevice) {
                Label("Switch to \(device.name)", systemImage: "speaker.wave.2")
            }
            
            Divider()
            
            // Shortcut management
            if device.shortcut != nil {
                Button(action: {
                    startRecordingShortcut()
                }) {
                    Label("Change Shortcut", systemImage: "keyboard")
                }
                
                Button(action: onClearShortcut) {
                    Label("Remove Shortcut", systemImage: "trash")
                }
            } else {
                Button(action: {
                    startRecordingShortcut()
                }) {
                    Label("Assign Shortcut", systemImage: "keyboard")
                }
            }
            
            Divider()
            
            // Device info
            Button(action: {}) {
                Label("\(device.transportType.rawValue) Device", systemImage: "info.circle")
            }
            .disabled(true)
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
        
        // Auto-cancel after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isRecordingShortcut {
                self.stopRecording()
            }
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Only handle keyDown events
        guard event.type == .keyDown else { return }
        
        // ESC to cancel
        if event.keyCode == 53 { // ESC key
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
            onSetShortcut(shortcut)
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

#Preview {
    VStack(spacing: 12) {
        DeviceRowView(
            device: AudioDevice(
                id: "1",
                name: "MacBook Pro Speakers",
                isOutput: true,
                transportType: .builtIn,
                isActive: true,
                shortcut: "⌘⌥1"
            ),
            isHovered: false,
            onSwitchDevice: {},
            onSetShortcut: { _ in },
            onClearShortcut: {}
        )
        
        DeviceRowView(
            device: AudioDevice(
                id: "2",
                name: "AirPods Pro",
                isOutput: true,
                transportType: .bluetooth,
                isActive: false,
                shortcut: nil
            ),
            isHovered: true,
            onSwitchDevice: {},
            onSetShortcut: { _ in },
            onClearShortcut: {}
        )
    }
    .padding()
    .frame(width: 500)
}