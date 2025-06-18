import Foundation
import Carbon
import AppKit

class ShortcutManager {
    static let shared = ShortcutManager()
    private var eventHotKey: EventHotKeyRef?
    
    private init() {}
    
    func setupShortcuts() {
        let shortcut = UserDefaults.standard.string(forKey: "globalShortcut") ?? "⌘⌥A"
        registerHotKey(from: shortcut)
    }
    
    func updateShortcut(_ shortcut: String) {
        // Unregister existing hotkey
        if let eventHotKey = eventHotKey {
            UnregisterEventHotKey(eventHotKey)
            self.eventHotKey = nil
        }
        
        // Register new hotkey
        registerHotKey(from: shortcut)
    }
    
    private func registerHotKey(from shortcut: String) {
        guard let (keyCode, modifiers) = parseShortcut(shortcut) else { return }
        
        var eventHotKey: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4153574B), id: 1) // ASWK
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )
        
        if status == noErr {
            self.eventHotKey = eventHotKey
            
            // Install event handler
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(
                GetApplicationEventTarget(),
                { _, event, _ in
                    AudioManager.shared.toggleBetweenLastTwo()
                    return noErr
                },
                1,
                &eventSpec,
                nil,
                nil
            )
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