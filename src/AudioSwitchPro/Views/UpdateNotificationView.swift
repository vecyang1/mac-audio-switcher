import SwiftUI

struct UpdateNotificationView: View {
    @ObservedObject var updateService = UpdateService.shared
    @State private var showingReleaseNotes = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Update Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Version \(updateService.latestVersion ?? "") is now available")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("You are currently running version \(getCurrentVersion())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Release Notes Button
            if updateService.releaseNotes != nil {
                Button("View Release Notes") {
                    showingReleaseNotes = true
                }
                .buttonStyle(.link)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Later") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Get Update") {
                    updateService.openPurchasePage()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 400)
        .sheet(isPresented: $showingReleaseNotes) {
            ReleaseNotesView(notes: updateService.releaseNotes ?? "")
        }
    }
    
    private func getCurrentVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}

struct ReleaseNotesView: View {
    let notes: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Release Notes")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                Text(notes)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 500, height: 400)
    }
}

// Update Badge View for Settings
struct UpdateBadgeView: View {
    @ObservedObject var updateService = UpdateService.shared
    
    var body: some View {
        if updateService.updateAvailable {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.white)
                
                Text("Update Available")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
    }
}