import SwiftUI

struct DeviceRowView: View {
    let device: AudioDevice
    let isHovered: Bool
    var showInputLevel: Bool = false
    let onSwitchDevice: () -> Void
    let onSetShortcut: (String) -> Void
    let onClearShortcut: () -> Void
    
    @State private var isRecordingShortcut = false
    @State private var eventMonitor: Any?
    @StateObject private var audioManager = AudioManager.shared
    
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
            // Star indicator for favorites
            if device.isStarred {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .frame(width: 16)
            } else {
                Color.clear
                    .frame(width: 16)
            }
            
            // Active Indicator
            if device.isActive {
                Image(systemName: device.isOutput ? "speaker.wave.3.fill" : "mic.fill")
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
            
            // Input Level Indicator (for input devices)
            if showInputLevel && !device.isOutput {
                HStack(spacing: 4) {
                    // Microphone icon to indicate what this is
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                        .foregroundColor(device.isActive ? .accentColor : .secondary)
                    
                    InputLevelIndicator(level: audioManager.getInputLevel(for: device.id))
                        .frame(width: 50, height: 8)
                        .help("Microphone input level")
                }
            }
            
            // Shortcut Section (always rightmost)
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
            if !isRecordingShortcut {
                // Allow clicking on all devices, including Bluetooth devices that might be available for connection
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
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
        Group {
            // Primary action
            Button(action: onSwitchDevice) {
                Label("Switch to \(device.name)", systemImage: device.isOutput ? "speaker.wave.2" : "mic.fill")
            }
            
            Divider()
            
            // Star/Unstar
            Button(action: {
                audioManager.toggleStar(for: device.id)
            }) {
                Label(device.isStarred ? "Remove from Favorites" : "Add to Favorites", 
                      systemImage: device.isStarred ? "star.slash" : "star")
            }
            
            // Hide device
            Button(action: {
                audioManager.hideDevice(device.id)
            }) {
                Label("Hide Device", systemImage: "eye.slash")
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

struct InputLevelIndicator: View {
    let level: Float // 0.0 to 1.0
    
    private var levelColor: Color {
        switch level {
        case 0.8...1.0:
            return .red // Too loud
        case 0.6..<0.8:
            return .yellow // Good level
        case 0.2..<0.6:
            return .green // Perfect
        default:
            return .gray // Too quiet
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background with segments
                HStack(spacing: 1) {
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: (geometry.size.width - 9) / 10)
                    }
                }
                
                // Active level bars
                HStack(spacing: 1) {
                    ForEach(0..<10) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Float(index) / 10.0 < level ? levelColor : Color.clear)
                            .frame(width: (geometry.size.width - 9) / 10)
                    }
                }
                .animation(.linear(duration: 0.05), value: level)
            }
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