import SwiftUI

struct DeviceShortcutsView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var editingDeviceID: String?
    @State private var isRecording = false
    @State private var recordedShortcut = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Device Shortcuts")
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
            
            // Device List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(audioManager.devices) { device in
                        DeviceShortcutRow(
                            device: device,
                            isEditing: editingDeviceID == device.id,
                            isRecording: isRecording && editingDeviceID == device.id,
                            onEdit: {
                                editingDeviceID = device.id
                                startRecordingShortcut()
                            },
                            onClear: {
                                audioManager.clearShortcut(for: device.id)
                            }
                        )
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Help Text
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Assign keyboard shortcuts to quickly switch to specific devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func startRecordingShortcut() {
        isRecording = true
        recordedShortcut = ""
        
        // Remove any existing event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Set up event monitor
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if self.isRecording {
                self.handleKeyEvent(event)
                return nil // Consume the event
            }
            return event
        }
    }
    
    @State private var eventMonitor: Any?
    
    private func handleKeyEvent(_ event: NSEvent) {
        // Only handle keyDown events for recording
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
        
        // Require at least one modifier key
        if keys.count >= 2 {
            let shortcut = keys.joined()
            
            // Check for conflicts
            let conflictDevice = audioManager.devices.first { device in
                device.shortcut == shortcut && device.id != editingDeviceID
            }
            
            if conflictDevice != nil {
                // Show conflict warning
                print("Shortcut \(shortcut) already assigned to \(conflictDevice?.name ?? "another device")")
                // For now, still assign it - you might want to show an alert
            }
            
            // Save the shortcut
            if let deviceID = editingDeviceID {
                audioManager.setShortcut(shortcut, for: deviceID)
                print("Assigned shortcut \(shortcut) to device \(deviceID)")
            }
            
            // Stop recording
            stopRecording()
        }
    }
    
    private func stopRecording() {
        isRecording = false
        editingDeviceID = nil
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

struct DeviceShortcutRow: View {
    let device: AudioDevice
    let isEditing: Bool
    let isRecording: Bool
    let onEdit: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Device Icon
            Image(systemName: device.transportType.icon)
                .font(.title2)
                .foregroundColor(device.isActive ? .accentColor : .secondary)
                .frame(width: 32)
            
            // Device Name
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.body)
                Text(device.transportType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Shortcut Display/Edit
            if let shortcut = device.shortcut {
                HStack(spacing: 8) {
                    Text(shortcut)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: onEdit) {
                    Text(isRecording ? "Press keys..." : "Set Shortcut")
                        .frame(minWidth: 100)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isRecording ? Color.accentColor : Color(NSColor.controlColor))
                        .foregroundColor(isRecording ? .white : .primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    DeviceShortcutsView(audioManager: AudioManager.shared)
}