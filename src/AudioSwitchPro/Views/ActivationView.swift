import SwiftUI

struct ActivationView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var activationMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                Text("Activate AudioSwitch Pro")
                    .font(.title)
                    .fontWeight(.bold)
                
                if licenseManager.isTrialExpired() {
                    Text("Your trial has expired")
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else {
                    Text("Enter your license key to unlock all features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 30)
            
            // License key input
            VStack(alignment: .leading, spacing: 8) {
                Text("License Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        activateLicense()
                    }
                
                if showError {
                    Text(activationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            
            // Buttons
            HStack(spacing: 15) {
                Button("Buy License") {
                    openPurchasePage()
                }
                .buttonStyle(.bordered)
                
                Button("Activate") {
                    activateLicense()
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.isEmpty || isActivating)
            }
            
            // Loading indicator
            if isActivating {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 5) {
                Text("Need help? Contact viviscallers@gmail.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !licenseManager.hasTrialStarted() {
                    Button("Start Free Trial") {
                        licenseManager.startTrial()
                        dismiss()
                    }
                    .font(.caption)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 450, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func activateLicense() {
        guard !licenseKey.isEmpty else { return }
        
        isActivating = true
        showError = false
        
        Task {
            let result = await licenseManager.activateLicense(licenseKey)
            
            await MainActor.run {
                isActivating = false
                
                if result.success {
                    // Show success briefly then dismiss
                    activationMessage = result.message
                    showError = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                } else {
                    activationMessage = result.message
                    showError = true
                }
            }
        }
    }
    
    private func openPurchasePage() {
        if let url = URL(string: "https://zylvie.com/products/edit/D8nvR78n") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct ActivationView_Previews: PreviewProvider {
    static var previews: some View {
        ActivationView()
    }
}