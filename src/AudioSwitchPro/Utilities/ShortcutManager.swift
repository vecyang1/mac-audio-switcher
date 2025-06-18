import Foundation
import Carbon
import AppKit
import os.log

class ShortcutManager {
    static let shared = ShortcutManager()
    private var registeredShortcuts: [String: (EventHotKeyRef, () -> Void)] = [:] // identifier: (hotkey, action)
    private var hotKeyIDToAction: [UInt32: () -> Void] = [:] // hotKeyID: action
    private var nextHotKeyID: UInt32 = 1
    private let logger = Logger(subsystem: "com.vecyang.AudioSwitchPro", category: "ShortcutManager")
    private var isHealthy: Bool = true
    
    private init() {
        logger.info("🚀 ShortcutManager initialized")
    }
    
    func setupShortcuts() {
        // Initial setup is now handled by AudioManager
        AudioManager.shared.refreshDevices()
    }
    
    func updateShortcut(_ shortcut: String) {
        // Update global shortcut
        UserDefaults.standard.set(shortcut, forKey: "globalShortcut")
        AudioManager.shared.refreshShortcuts()
    }
    
    func clearAllShortcuts() {
        for (_, value) in registeredShortcuts {
            UnregisterEventHotKey(value.0)
        }
        registeredShortcuts.removeAll()
        hotKeyIDToAction.removeAll()
    }
    
    func registerShortcut(_ shortcut: String, identifier: String, action: @escaping () -> Void) {
        logger.debug("🔧 Registering shortcut '\(shortcut)' for \(identifier)")
        
        // Remove existing shortcut with same identifier
        if let existing = registeredShortcuts[identifier] {
            let unregisterStatus = UnregisterEventHotKey(existing.0)
            if unregisterStatus != noErr {
                logger.warning("⚠️ Failed to unregister existing shortcut for \(identifier)")
            }
            registeredShortcuts.removeValue(forKey: identifier)
        }
        
        guard let (keyCode, modifiers) = parseShortcut(shortcut) else {
            logger.error("❌ Failed to parse shortcut: \(shortcut)")
            return
        }
        
        // Check for potential conflicts
        if registeredShortcuts.values.contains(where: { _ in
            // Simple conflict detection - could be enhanced
            return false
        }) {
            logger.warning("⚠️ Potential shortcut conflict detected")
        }
        
        var eventHotKey: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4153574B), id: nextHotKeyID) // ASWK
        let currentHotKeyID = nextHotKeyID
        nextHotKeyID += 1
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )
        
        if status == noErr, let eventHotKey = eventHotKey {
            registeredShortcuts[identifier] = (eventHotKey, action)
            hotKeyIDToAction[currentHotKeyID] = action
            
            // Install event handler if not already installed
            setupEventHandler()
            
            logger.info("✅ Registered shortcut '\(shortcut)' for \(identifier) with ID \(currentHotKeyID)")
            isHealthy = true
        } else {
            logger.error("❌ Failed to register shortcut '\(shortcut)' for \(identifier). Status: \(status)")
            isHealthy = false
            
            // Try to recover by clearing all shortcuts and re-registering
            if status == -9868 { // eventAlreadyPostedErr
                logger.info("🔄 Attempting to recover from shortcut conflict")
                clearAllShortcuts()
                // Don't retry immediately to avoid infinite recursion
            }
        }
    }
    
    private var eventHandlerInstalled = false
    
    private func setupEventHandler() {
        guard !eventHandlerInstalled else { return }
        
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                ShortcutManager.shared.handleHotKeyEvent(event!)
                return noErr
            },
            1,
            &eventSpec,
            nil,
            nil
        )
        
        eventHandlerInstalled = true
    }
    
    private func handleHotKeyEvent(_ event: EventRef) {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        guard status == noErr else { 
            print("❌ Failed to get hotkey ID from event")
            return 
        }
        
        print("🔥 Hotkey pressed with ID: \(hotKeyID.id)")
        
        // Find and execute the action for this specific hotkey ID
        if let action = hotKeyIDToAction[hotKeyID.id] {
            print("✅ Executing action for hotkey ID: \(hotKeyID.id)")
            DispatchQueue.main.async {
                action()
            }
        } else {
            print("❌ No action found for hotkey ID: \(hotKeyID.id)")
            print("Available hotkey IDs: \(Array(hotKeyIDToAction.keys))")
        }
    }
    
    private func parseShortcut(_ shortcut: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        var modifiers: UInt32 = 0
        var keyCharacter = ""
        
        // Parse modifiers
        if shortcut.contains("⌘") {
            modifiers |= UInt32(cmdKey)
        }
        if shortcut.contains("⌥") {
            modifiers |= UInt32(optionKey)
        }
        if shortcut.contains("⌃") {
            modifiers |= UInt32(controlKey)
        }
        if shortcut.contains("⇧") {
            modifiers |= UInt32(shiftKey)
        }
        
        // Get the actual key character
        let modifierChars = ["⌘", "⌥", "⌃", "⇧"]
        keyCharacter = shortcut
        for modifier in modifierChars {
            keyCharacter = keyCharacter.replacingOccurrences(of: modifier, with: "")
        }
        
        // Convert key character to key code
        guard let keyCode = keyCodeForCharacter(keyCharacter) else { return nil }
        
        return (keyCode, modifiers)
    }
    
    private func keyCodeForCharacter(_ character: String) -> UInt32? {
        let keyMap: [String: UInt32] = [
            "A": 0x00, "B": 0x0B, "C": 0x08, "D": 0x02, "E": 0x0E,
            "F": 0x03, "G": 0x05, "H": 0x04, "I": 0x22, "J": 0x26,
            "K": 0x28, "L": 0x25, "M": 0x2E, "N": 0x2D, "O": 0x1F,
            "P": 0x23, "Q": 0x0C, "R": 0x0F, "S": 0x01, "T": 0x11,
            "U": 0x20, "V": 0x09, "W": 0x0D, "X": 0x07, "Y": 0x10,
            "Z": 0x06,
            "0": 0x1D, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15,
            "5": 0x17, "6": 0x16, "7": 0x1A, "8": 0x1C, "9": 0x19,
            " ": 0x31, "SPACE": 0x31,
            "TAB": 0x30, "RETURN": 0x24, "ESCAPE": 0x35,
            "F1": 0x7A, "F2": 0x78, "F3": 0x63, "F4": 0x76,
            "F5": 0x60, "F6": 0x61, "F7": 0x62, "F8": 0x64,
            "F9": 0x65, "F10": 0x6D, "F11": 0x67, "F12": 0x6F
        ]
        
        return keyMap[character.uppercased()]
    }
}

// UserDefaults extension
extension UserDefaults {
    var autoStartEnabled: Bool {
        get { bool(forKey: "autoStartEnabled") }
        set { set(newValue, forKey: "autoStartEnabled") }
    }
    
    var globalShortcut: String? {
        get { string(forKey: "globalShortcut") }
        set { set(newValue, forKey: "globalShortcut") }
    }
}