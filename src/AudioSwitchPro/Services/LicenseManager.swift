import Foundation
import CryptoKit

class LicenseManager: ObservableObject {
    static let shared = LicenseManager()
    
    // Configuration
    private let productId = "D8nvR78n"
    private let apiKey = "459c750d7730496f9e6c57191808633d"
    private let adminCode = "AdmincodeV"
    private let trialDays = 1 // Set to 1 day as requested
    private let apiBaseURL = "https://api.zylvie.com"
    
    // Keys for UserDefaults
    private let trialStartKey = "ASP_TrialStart_v2"
    private let licenseKeyKey = "ASP_LicenseKey_v2"
    private let licenseValidatedKey = "ASP_LicenseValidated_v2"
    private let licenseEmailKey = "ASP_LicenseEmail_v2"
    
    // Published properties for UI binding
    @Published var isActivated = false
    @Published var trialDaysRemaining = 0
    @Published var trialHoursRemaining = 0
    @Published var licenseEmail: String?
    
    private init() {
        checkLicenseStatus()
    }
    
    // MARK: - Public Methods
    
    func checkLicenseStatus() {
        // Check if admin code is stored
        if let storedKey = getStoredLicenseKey(), storedKey == adminCode {
            isActivated = true
            licenseEmail = "Admin User"
            return
        }
        
        // Check if regular license is validated
        if let storedKey = getStoredLicenseKey(),
           UserDefaults.standard.bool(forKey: licenseValidatedKey) {
            isActivated = true
            licenseEmail = UserDefaults.standard.string(forKey: licenseEmailKey)
            // Periodically revalidate online (every 7 days)
            if shouldRevalidate() {
                Task {
                    await revalidateLicense(storedKey)
                }
            }
            return
        }
        
        // Check trial status
        checkTrialStatus()
    }
    
    func activateLicense(_ licenseKey: String) async -> (success: Bool, message: String) {
        let trimmedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for admin code
        if trimmedKey == adminCode {
            storeLicenseKey(adminCode)
            UserDefaults.standard.set(true, forKey: licenseValidatedKey)
            UserDefaults.standard.set("Admin User", forKey: licenseEmailKey)
            DispatchQueue.main.async {
                self.isActivated = true
                self.licenseEmail = "Admin User"
            }
            return (true, "Admin access activated successfully!")
        }
        
        // Validate format (UUID)
        guard isValidUUID(trimmedKey) else {
            return (false, "Invalid license key format")
        }
        
        // Verify with API
        do {
            let result = try await verifyLicenseWithAPI(trimmedKey)
            if result.isValid {
                // Mark as redeemed
                let redeemResult = try await redeemLicenseWithAPI(trimmedKey)
                if redeemResult.success {
                    storeLicenseKey(trimmedKey)
                    UserDefaults.standard.set(true, forKey: licenseValidatedKey)
                    UserDefaults.standard.set(result.email, forKey: licenseEmailKey)
                    UserDefaults.standard.set(Date(), forKey: "ASP_LastValidation")
                    
                    DispatchQueue.main.async {
                        self.isActivated = true
                        self.licenseEmail = result.email
                    }
                    return (true, "License activated successfully!")
                } else {
                    return (false, redeemResult.message)
                }
            } else {
                return (false, result.message)
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }
    
    func startTrial() {
        let trialStart = Date()
        let encrypted = encryptDate(trialStart)
        UserDefaults.standard.set(encrypted, forKey: trialStartKey)
        checkTrialStatus()
    }
    
    func hasTrialStarted() -> Bool {
        return UserDefaults.standard.data(forKey: trialStartKey) != nil
    }
    
    func isTrialExpired() -> Bool {
        guard !isActivated else { return false }
        return trialDaysRemaining <= 0 && hasTrialStarted()
    }
    
    func resetLicense() {
        // For testing purposes only
        UserDefaults.standard.removeObject(forKey: trialStartKey)
        UserDefaults.standard.removeObject(forKey: licenseKeyKey)
        UserDefaults.standard.removeObject(forKey: licenseValidatedKey)
        UserDefaults.standard.removeObject(forKey: licenseEmailKey)
        UserDefaults.standard.removeObject(forKey: "ASP_LastValidation")
        checkLicenseStatus()
    }
    
    // MARK: - Private Methods
    
    private func checkTrialStatus() {
        guard let encryptedData = UserDefaults.standard.data(forKey: trialStartKey),
              let trialStart = decryptDate(encryptedData) else {
            // Trial not started
            trialDaysRemaining = trialDays
            trialHoursRemaining = trialDays * 24
            return
        }
        
        let elapsed = Date().timeIntervalSince(trialStart)
        let remainingSeconds = Double(trialDays * 24 * 60 * 60) - elapsed
        
        if remainingSeconds > 0 {
            trialDaysRemaining = Int(ceil(remainingSeconds / 86400))
            trialHoursRemaining = Int(ceil(remainingSeconds / 3600))
        } else {
            trialDaysRemaining = 0
            trialHoursRemaining = 0
        }
    }
    
    private func verifyLicenseWithAPI(_ licenseKey: String) async throws -> (isValid: Bool, message: String, email: String?) {
        guard let url = URL(string: "\(apiBaseURL)/licensekeys/verify") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Add query parameters
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "product_id", value: productId),
            URLQueryItem(name: "license_key", value: licenseKey)
        ]
        request.url = components?.url
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 404 {
            return (false, "Invalid license key", nil)
        }
        
        guard httpResponse.statusCode == 200 else {
            return (false, "Server error: \(httpResponse.statusCode)", nil)
        }
        
        let result = try JSONDecoder().decode(LicenseVerifyResponse.self, from: data)
        
        // Check if already refunded
        if result.refunded {
            return (false, "This license has been refunded", nil)
        }
        
        // Check if already redeemed by someone else
        if result.redeemed && !isCurrentDeviceLicense(licenseKey) {
            return (false, "This license has already been activated on another device", nil)
        }
        
        return (true, "Valid license", result.buyer_email)
    }
    
    private func redeemLicenseWithAPI(_ licenseKey: String) async throws -> (success: Bool, message: String) {
        guard let url = URL(string: "\(apiBaseURL)/licensekeys/redeem") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "license_key=\(licenseKey)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 200 {
            return (true, "License redeemed successfully")
        }
        
        // Try to parse error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            if errorResponse.error == "Already redeemed" {
                // If it's our own license, that's OK
                if isCurrentDeviceLicense(licenseKey) {
                    return (true, "License verified")
                }
            }
            return (false, errorResponse.error)
        }
        
        return (false, "Failed to redeem license")
    }
    
    private func revalidateLicense(_ licenseKey: String) async {
        do {
            let result = try await verifyLicenseWithAPI(licenseKey)
            if !result.isValid {
                // License no longer valid, deactivate
                DispatchQueue.main.async {
                    self.isActivated = false
                    UserDefaults.standard.set(false, forKey: self.licenseValidatedKey)
                }
            } else {
                // Update last validation date
                UserDefaults.standard.set(Date(), forKey: "ASP_LastValidation")
            }
        } catch {
            // Ignore network errors during revalidation
            print("Revalidation error (ignored): \(error)")
        }
    }
    
    private func shouldRevalidate() -> Bool {
        guard let lastValidation = UserDefaults.standard.object(forKey: "ASP_LastValidation") as? Date else {
            return true
        }
        let daysSinceValidation = Date().timeIntervalSince(lastValidation) / 86400
        return daysSinceValidation > 7
    }
    
    private func isCurrentDeviceLicense(_ licenseKey: String) -> Bool {
        return getStoredLicenseKey() == licenseKey
    }
    
    private func isValidUUID(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
    
    private func storeLicenseKey(_ key: String) {
        let encrypted = encryptString(key)
        UserDefaults.standard.set(encrypted, forKey: licenseKeyKey)
    }
    
    private func getStoredLicenseKey() -> String? {
        guard let encrypted = UserDefaults.standard.data(forKey: licenseKeyKey) else { return nil }
        return decryptString(encrypted)
    }
    
    // MARK: - Encryption Methods
    
    private func encryptDate(_ date: Date) -> Data {
        let dateString = String(date.timeIntervalSince1970)
        return encryptString(dateString) ?? Data()
    }
    
    private func decryptDate(_ data: Data) -> Date? {
        guard let dateString = decryptString(data),
              let timeInterval = Double(dateString) else { return nil }
        return Date(timeIntervalSince1970: timeInterval)
    }
    
    private func encryptString(_ string: String) -> Data? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        // Simple XOR encryption with a key (not cryptographically secure, but prevents casual tampering)
        let key = "ASP2024Trial".data(using: .utf8)!
        var encrypted = Data()
        
        for i in 0..<data.count {
            let byte = data[i] ^ key[i % key.count]
            encrypted.append(byte)
        }
        
        return encrypted
    }
    
    private func decryptString(_ data: Data) -> String? {
        // XOR encryption is symmetric - apply same operation to decrypt
        let key = "ASP2024Trial".data(using: .utf8)!
        var decrypted = Data()
        
        for i in 0..<data.count {
            let byte = data[i] ^ key[i % key.count]
            decrypted.append(byte)
        }
        
        return String(data: decrypted, encoding: .utf8)
    }
}

// MARK: - Response Models

private struct LicenseVerifyResponse: Codable {
    let key: String
    let product_id: String
    let buyer_email: String?
    let created: Int
    let redeemed: Bool
    let redeemed_at: Int?
    let refunded: Bool
    let refunded_at: Int?
}

private struct ErrorResponse: Codable {
    let error: String
}