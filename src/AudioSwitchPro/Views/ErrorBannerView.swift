import SwiftUI

struct ErrorBannerView: View {
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio System Issue")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ErrorBannerView(error: "Failed to connect to audio system") {
        print("Retry tapped")
    }
    .padding()
}