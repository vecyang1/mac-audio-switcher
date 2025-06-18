import SwiftUI

struct DeviceRowView: View {
    let device: AudioDevice
    let isHovered: Bool
    
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
                    .foregroundColor(device.isActive ? .primary : .primary.opacity(0.9))
                
                HStack(spacing: 8) {
                    Text(device.transportType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if device.isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            Spacer()
            
            // Active Indicator
            if device.isActive {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.body)
                    .foregroundColor(.accentColor)
                    // .symbolEffect(.variableColor.iterative, isActive: device.isActive) // Available in macOS 14+
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
                isActive: true
            ),
            isHovered: false
        )
        
        DeviceRowView(
            device: AudioDevice(
                id: "2",
                name: "AirPods Pro",
                isOutput: true,
                transportType: .bluetooth,
                isActive: false
            ),
            isHovered: true
        )
    }
    .padding()
    .frame(width: 400)
}