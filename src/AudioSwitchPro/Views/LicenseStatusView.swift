import SwiftUI

struct LicenseStatusView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showActivation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // License Status
            HStack {
                if licenseManager.isActivated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Licensed")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if let email = licenseManager.licenseEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if licenseManager.hasTrialStarted() {
                    Image(systemName: "clock.fill")
                        .foregroundColor(licenseManager.trialDaysRemaining > 0 ? .blue : .red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if licenseManager.trialDaysRemaining > 0 {
                            if licenseManager.trialHoursRemaining <= 24 {
                                Text("Trial: \(licenseManager.trialHoursRemaining) hours remaining")
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                Text("Trial: \(licenseManager.trialDaysRemaining) days remaining")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        } else {
                            Text("Trial Expired")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        }
                        
                        Text("Limited functionality")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Not Activated")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("Trial not started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !licenseManager.isActivated {
                    Button("Activate") {
                        showActivation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            // Purchase button for expired trials
            if licenseManager.isTrialExpired() && !licenseManager.isActivated {
                Button("Purchase License") {
                    if let url = URL(string: "https://zylvie.com/products/edit/D8nvR78n") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Debug reset button (remove in production)
            #if DEBUG
            Divider()
            
            Button("Reset License (Debug)") {
                licenseManager.resetLicense()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)
            #endif
        }
        .sheet(isPresented: $showActivation) {
            ActivationView()
        }
    }
}

struct LicenseStatusView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseStatusView()
            .padding()
    }
}