import Foundation

struct Bottle: Identifiable, Codable, Hashable {
    
    // MARK: - Identity
    let id:        UUID
    var name:      String
    var path:      URL
    var createdAt: Date
    
    // MARK: - Configuration
    var windowsVersion: WindowsVersion
    var engineType:     EngineType
    var programs:       [Program]
    
    // MARK: - Performance
    var esync:              Bool
    var msync:              Bool
    var dxvk:               Bool
    var metalHUD:           Bool
    var dxvkHUD:            Bool
    var retinaMode:         Bool
    var highPerformanceGPU: Bool
    
    // MARK: - Init
    init(
        name:           String,
        windowsVersion: WindowsVersion = .windows10,
        engineType:     EngineType     = .gptk
    ) {
        self.id             = UUID()
        self.name           = name
        self.createdAt      = Date()
        self.windowsVersion = windowsVersion
        self.engineType     = engineType
        self.programs       = []
        
        // Smart defaults for Apple Silicon
        self.esync              = true
        self.msync              = true
        self.dxvk               = true
        self.metalHUD           = false
        self.dxvkHUD            = false
        self.retinaMode         = true
        self.highPerformanceGPU = true
        
        self.path = Bottle.bottlesDirectory
            .appendingPathComponent(id.uuidString)
    }
    
    // MARK: - Computed
    var cDrivePath: URL {
        path.appendingPathComponent("drive_c")
    }
    
    var isInitialized: Bool {
        FileManager.default.fileExists(atPath: cDrivePath.path)
    }
    
    var programCount: String {
        "\(programs.count) \(programs.count == 1 ? "program" : "programs")"
    }
    
    // MARK: - Storage location
    static var bottlesDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Bourbon/Bottles")
    }
    
    // MARK: - Windows Version
    enum WindowsVersion: String, Codable, CaseIterable {
        case windows11 = "win11"
        case windows10 = "win10"
        case windows81 = "win81"
        case windows7  = "win7"
        case windowsXP = "winxp"
        
        var displayName: String {
            switch self {
            case .windows11: return "Windows 11"
            case .windows10: return "Windows 10"
            case .windows81: return "Windows 8.1"
            case .windows7:  return "Windows 7"
            case .windowsXP: return "Windows XP"
            }
        }
    }
    
    // MARK: - Engine Type
    enum EngineType: String, Codable, CaseIterable {
        case gptk = "gptk"
        case wine = "wine"
        
        var displayName: String {
            switch self {
            case .gptk: return "Game Porting Toolkit"
            case .wine: return "Wine"
            }
        }
    }
}
