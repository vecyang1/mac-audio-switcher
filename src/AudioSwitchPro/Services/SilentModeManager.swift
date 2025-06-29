import Foundation
import AppKit
import Combine

class SilentModeManager: ObservableObject {
    static let shared = SilentModeManager()
    
    @Published var silentModeApps: [SilentModeApp] = []
    @Published var currentActiveApp: String? = nil
    @Published var isSilentModeActive: Bool = false
    
    private var workspaceObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSilentModeApps()
        setupActiveAppMonitoring()
        
        // Save apps whenever the list changes
        $silentModeApps
            .dropFirst()
            .sink { [weak self] apps in
                self?.saveSilentModeApps(apps)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupActiveAppMonitoring() {
        // Get initial active app
        updateActiveApp()
        
        // Monitor app switches
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.updateActiveApp()
        }
    }
    
    private func updateActiveApp() {
        if let activeApp = NSWorkspace.shared.frontmostApplication {
            currentActiveApp = activeApp.bundleIdentifier
            checkSilentModeStatus()
        }
    }
    
    private func checkSilentModeStatus() {
        guard let currentApp = currentActiveApp else {
            isSilentModeActive = false
            return
        }
        
        let wasActive = isSilentModeActive
        
        // Check if current app is in silent mode list and enabled
        isSilentModeActive = silentModeApps.contains { app in
            app.id == currentApp && app.isEnabled
        }
        
        print("🔇 Silent mode active: \(isSilentModeActive) for app: \(currentApp)")
        
        // If silent mode state changed, notify AudioManager to refresh shortcuts
        if wasActive != isSilentModeActive {
            print("🔄 Silent mode state changed from \(wasActive) to \(isSilentModeActive)")
            NotificationCenter.default.post(name: Notification.Name("SilentModeStateChanged"), object: nil)
        }
    }
    
    // MARK: - App Management
    
    func addApp(_ app: SilentModeApp) {
        // Avoid duplicates
        if !silentModeApps.contains(where: { $0.id == app.id }) {
            silentModeApps.append(app)
            checkSilentModeStatus()
        }
    }
    
    func removeApp(_ app: SilentModeApp) {
        silentModeApps.removeAll { $0.id == app.id }
        checkSilentModeStatus()
    }
    
    func toggleApp(_ app: SilentModeApp) {
        if let index = silentModeApps.firstIndex(where: { $0.id == app.id }) {
            silentModeApps[index].isEnabled.toggle()
            checkSilentModeStatus()
        }
    }
    
    func updateApp(_ app: SilentModeApp) {
        if let index = silentModeApps.firstIndex(where: { $0.id == app.id }) {
            silentModeApps[index] = app
            checkSilentModeStatus()
        }
    }
    
    // MARK: - Persistence
    
    private func loadSilentModeApps() {
        silentModeApps = UserDefaults.standard.silentModeApps
    }
    
    private func saveSilentModeApps(_ apps: [SilentModeApp]) {
        UserDefaults.standard.silentModeApps = apps
    }
    
    // MARK: - App Selection
    
    func selectAppsToAdd(completion: @escaping ([SilentModeApp]) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Applications"
        openPanel.message = "Choose applications to add to Silent Mode"
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [.application]
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        openPanel.begin { response in
            guard response == .OK else { return }
            
            let newApps = openPanel.urls.compactMap { url in
                SilentModeApp.fromURL(url)
            }
            
            DispatchQueue.main.async {
                completion(newApps)
            }
        }
    }
}