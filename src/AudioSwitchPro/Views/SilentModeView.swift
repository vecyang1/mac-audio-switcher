import SwiftUI
import AppKit

struct SilentModeView: View {
    @StateObject private var silentModeManager = SilentModeManager.shared
    @State private var selectedApps: Set<SilentModeApp> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with description
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "speaker.slash.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Silent Mode")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
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
                .padding(.top, 4)
            }
            
            Divider()
            
            // Apps list
            if silentModeManager.silentModeApps.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No apps in Silent Mode")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add apps to disable shortcuts when they're active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header row
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
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        Divider()
                        
                        // App rows
                        ForEach(silentModeManager.silentModeApps) { app in
                            SilentModeAppRow(app: app, isSelected: selectedApps.contains(app)) {
                                if selectedApps.contains(app) {
                                    selectedApps.remove(app)
                                } else {
                                    selectedApps.insert(app)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedApps.contains(app) ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                            
                            if app != silentModeManager.silentModeApps.last {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Bottom controls
            HStack {
                Button(action: addApps) {
                    Image(systemName: "plus")
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.borderless)
                .help("Add applications to Silent Mode")
                
                Button(action: removeSelectedApps) {
                    Image(systemName: "minus")
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.borderless)
                .disabled(selectedApps.isEmpty)
                .help("Remove selected applications")
                
                Spacer()
                
                if silentModeManager.isSilentModeActive {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.slash.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Silent Mode Active")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .frame(width: 500)
    }
    
    private func addApps() {
        silentModeManager.selectAppsToAdd { newApps in
            for app in newApps {
                silentModeManager.addApp(app)
            }
        }
    }
    
    private func removeSelectedApps() {
        for app in selectedApps {
            silentModeManager.removeApp(app)
        }
        selectedApps.removeAll()
    }
}

struct SilentModeAppRow: View {
    let app: SilentModeApp
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var silentModeManager = SilentModeManager.shared
    
    var body: some View {
        HStack {
            // App icon and info
            HStack(spacing: 12) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    
                    Text(app.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Spacer()
            
            // Toggle switch
            Toggle("", isOn: Binding(
                get: { app.isEnabled },
                set: { _ in
                    silentModeManager.toggleApp(app)
                }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    SilentModeView()
        .frame(width: 500, height: 400)
}