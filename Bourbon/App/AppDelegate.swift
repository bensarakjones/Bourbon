import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupAppearance()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return true
    }
    
    private func setupAppearance() {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(
                red: 0.10,
                green: 0.06,
                blue: 0.03,
                alpha: 1.0
            )
        }
    }
}
