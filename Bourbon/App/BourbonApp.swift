import SwiftUI

@main
struct BourbonApp: App {
    
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            BourbonSettingsView()
                .environmentObject(appState)
        }
    }
}
