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
                VStack(spacing: 12) {
                    ForEach(audioManager.devices) { device in
                        DeviceRowView(
                            device: device,
                            isHovered: hoveredDeviceID == device.id,
                            onSwitchDevice: {
                                audioManager.switchToDevice(device.id)
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
                .padding()
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
    }
}

struct HeaderView: View {
    @Binding var showSettings: Bool
    
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
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
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
        .frame(width: 450, height: 600)
}