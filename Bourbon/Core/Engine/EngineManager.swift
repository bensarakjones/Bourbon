import Foundation

// MARK: - Engine Model
struct BourbonEngine {
    let type:      EngineType
    let binaryURL: URL
    
    var name: String { type.displayName }
    
    enum EngineType: String, Codable {
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

// MARK: - Manager
class EngineManager {
    
    static let shared = EngineManager()
    private init() {}
    
    // Wine binary names to search for
    private let wineBinaryNames = [
        "wine64",
        "wine"
    ]
    
    // Directories to search in
    private let searchDirectories = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/Applications/Wine Stable.app/Contents/Resources/wine/bin",
        "/usr/local/opt/wine-stable/bin",
        "/opt/homebrew/opt/wine-stable/bin"
    ]
    
    // MARK: - Check if anything is installed
    func isInstalled() async -> Bool {
        return findWine() != nil
    }
    
    // MARK: - Find GPTK
    func findGPTK() async -> URL? {
        // GPTK not available right now so return nil
        return nil
    }
    
    // MARK: - Find Wine binary
    func findWine() -> URL? {
        for dir in searchDirectories {
            for binary in wineBinaryNames {
                let fullPath = "\(dir)/\(binary)"
                if FileManager.default.fileExists(atPath: fullPath) {
                    return URL(fileURLWithPath: fullPath)
                }
            }
        }
        return nil
    }
    
    // MARK: - Best available engine
    func preferredEngine() async -> BourbonEngine? {
        if let wine = findWine() {
            return BourbonEngine(type: .wine, binaryURL: wine)
        }
        return nil
    }
    
    // MARK: - Version string
    func version(of engine: BourbonEngine) async -> String {
        let result = try? await ProcessRunner.run(
            [engine.binaryURL.path, "--version"]
        )
        return result?.stdout
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "Unknown"
    }
}
