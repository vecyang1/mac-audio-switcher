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
            
            // Device List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(audioManager.devices) { device in
                        DeviceRowView(
                            device: device,
                            isHovered: hoveredDeviceID == device.id
                        )
                        .onHover { isHovered in
                            hoveredDeviceID = isHovered ? device.id : nil
                        }
                        .onTapGesture {
                            audioManager.switchToDevice(device.id)
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
                Text("Click any device to switch")
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
    @AppStorage("globalShortcut") private var shortcut = "⌘⌥A"
    
    var body: some View {
        HStack {
            Label("Toggle shortcut", systemImage: "keyboard")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(shortcut)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 450, height: 600)
}