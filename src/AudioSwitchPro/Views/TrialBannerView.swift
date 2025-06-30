import SwiftUI

struct TrialBannerView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showActivation = false
    
    var body: some View {
        if !licenseManager.isActivated && licenseManager.hasTrialStarted() {
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(bannerColor)
                
                if licenseManager.trialDaysRemaining > 0 {
                    if licenseManager.trialHoursRemaining <= 24 {
                        Text("Trial: \(licenseManager.trialHoursRemaining) hours remaining")
                            .font(.caption)
                            .fontWeight(.medium)
                    } else {
                        Text("Trial: \(licenseManager.trialDaysRemaining) days remaining")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                } else {
                    Text("Trial Expired")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button("Activate") {
                    showActivation = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bannerBackground)
            .sheet(isPresented: $showActivation) {
                ActivationView()
            }
        }
    }
    
    private var bannerColor: Color {
        if licenseManager.trialDaysRemaining <= 0 {
            return .red
        } else if licenseManager.trialHoursRemaining <= 6 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var bannerBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(bannerColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(bannerColor.opacity(0.3), lineWidth: 1)
            )
    }
}

struct TrialBannerView_Previews: PreviewProvider {
    static var previews: some View {
        TrialBannerView()
            .padding()
    }
}