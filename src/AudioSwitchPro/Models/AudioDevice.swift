import Foundation

struct AudioDevice: Identifiable, Equatable, Codable {
    let id: String              // Device UID
    let name: String            // Display name
    let isOutput: Bool          // Output device flag
    let transportType: TransportType
    var isActive: Bool          // Currently selected
    var shortcut: String?       // Custom keyboard shortcut
    var isOnline: Bool = true   // Whether device is currently connected
    
    enum TransportType: String, Codable {
        case bluetooth = "Bluetooth"
        case usb = "USB"
        case displayPort = "DisplayPort"
        case hdmi = "HDMI"
        case builtIn = "Built-in"
        case virtual = "Virtual"
        case thunderbolt = "Thunderbolt"
        case airPlay = "AirPlay"
        case unknown = "Unknown"
        
        var icon: String {
            switch self {
            case .bluetooth:
                return "airpodspro"
            case .usb, .displayPort, .hdmi, .thunderbolt:
                return "cable.connector"
            case .builtIn:
                return "speaker.wave.2"
            case .airPlay:
                return "airplayaudio"
            case .virtual, .unknown:
                return "speaker"
            }
        }
    }
    
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.id == rhs.id
    }
}