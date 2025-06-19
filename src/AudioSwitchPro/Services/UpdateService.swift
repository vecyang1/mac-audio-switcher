import Foundation
import AppKit

class UpdateService: ObservableObject {
    static let shared = UpdateService()
    
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var purchaseURL: String?
    @Published var releaseNotes: String?
    @Published var isChecking = false
    
    private let currentVersion: String
    // Replace with your WordPress site URL - this endpoint should return JSON with version info
    // Expected JSON format:
    // {
    //   "version": "1.1.0",
    //   "release_notes": "New features...",
    //   "purchase_url": "https://yourwebsite.com/purchase/audioswitchpro"
    // }
    private let updateCheckURL = "https://yourwebsite.com/api/audioswitchpro/version"
    private var updateCheckTimer: Timer?
    
    init() {
        // Get current version from bundle
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.currentVersion = version
        } else {
            self.currentVersion = "1.0.0"
        }
    }
    
    func startAutoUpdateCheck() {
        // Check immediately on start
        checkForUpdates()
        
        // Then check every 24 hours
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            self.checkForUpdates()
        }
    }
    
    func stopAutoUpdateCheck() {
        updateCheckTimer?.invalidate()
        updateCheckTimer = nil
    }
    
    func checkForUpdates(completion: ((Bool) -> Void)? = nil) {
        guard !isChecking else { 
            completion?(false)
            return 
        }
        
        isChecking = true
        
        guard let url = URL(string: updateCheckURL) else {
            isChecking = false
            completion?(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                if let error = error {
                    print("Update check failed: \(error)")
                    completion?(false)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let latestVersion = json["version"] as? String else {
                    completion?(false)
                    return
                }
                
                // Compare versions
                if let current = self?.currentVersion,
                   self?.isNewerVersion(latestVersion, than: current) == true {
                    
                    self?.latestVersion = latestVersion
                    self?.updateAvailable = true
                    
                    // Get purchase URL from your server
                    if let purchaseURL = json["purchase_url"] as? String {
                        self?.purchaseURL = purchaseURL
                    }
                    
                    // Get release notes
                    if let body = json["body"] as? String {
                        self?.releaseNotes = body
                    }
                    
                    // Show notification if app is not active
                    if !NSApp.isActive {
                        self?.showUpdateNotification()
                    }
                    
                    completion?(true)
                } else {
                    self?.updateAvailable = false
                    completion?(false)
                }
            }
        }.resume()
    }
    
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newNum = i < newComponents.count ? newComponents[i] : 0
            let currentNum = i < currentComponents.count ? currentComponents[i] : 0
            
            if newNum > currentNum {
                return true
            } else if newNum < currentNum {
                return false
            }
        }
        
        return false
    }
    
    private func showUpdateNotification() {
        let notification = NSUserNotification()
        notification.title = "AudioSwitch Pro Update Available"
        notification.informativeText = "Version \(latestVersion ?? "") is now available"
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.actionButtonTitle = "Update"
        notification.otherButtonTitle = "Later"
        notification.hasActionButton = true
        
        NSUserNotificationCenter.default.delegate = NotificationDelegate.shared
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func openPurchasePage() {
        if let urlString = purchaseURL,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to main website
            if let url = URL(string: "https://yourwebsite.com/audioswitchpro") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// Notification delegate for handling update notifications
class NotificationDelegate: NSObject, NSUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if notification.activationType == .actionButtonClicked {
            UpdateService.shared.openPurchasePage()
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}