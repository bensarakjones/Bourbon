import Foundation
import AppKit

struct Program: Identifiable, Codable, Hashable {
    
    let id:              UUID
    var name:            String
    var executableURL:   URL
    var launchArguments: [String]
    var lastLaunched:    Date?
    var iconData:        Data?
    var isFavorite:      Bool
    var totalPlayTime:   TimeInterval
    
    // MARK: - Init
    init(name: String, executableURL: URL) {
        self.id              = UUID()
        self.name            = name
        self.executableURL   = executableURL
        self.launchArguments = []
        self.lastLaunched    = nil
        self.iconData        = nil
        self.isFavorite      = false
        self.totalPlayTime   = 0
    }
    
    // MARK: - Icon
    var icon: NSImage {
        if let data  = iconData,
           let image = NSImage(data: data) {
            return image
        }
        return NSImage(
            systemSymbolName: "app.fill",
            accessibilityDescription: "Program icon"
        ) ?? NSImage()
    }
    
    // MARK: - Formatted play time
    var formattedPlayTime: String {
        guard totalPlayTime > 60 else { return "Never played" }
        let hours   = Int(totalPlayTime) / 3600
        let minutes = Int(totalPlayTime) % 3600 / 60
        if hours > 0 { return "\(hours)h \(minutes)m played" }
        return "\(minutes)m played"
    }
    
    // MARK: - Formatted last launched
    var formattedLastLaunched: String {
        guard let date = lastLaunched else { return "Never" }
        let formatter           = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
