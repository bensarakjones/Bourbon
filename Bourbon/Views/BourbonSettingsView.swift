import SwiftUI

struct BourbonSettingsView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .general
    
    enum SettingsSection: String, CaseIterable {
        case general = "General"
        case engine  = "Engine"
        case about   = "About"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .engine:  return "cpu"
            case .about:   return "info.circle"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedSection) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsSection.general)
            
            EngineSettingsView()
                .tabItem {
                    Label("Engine", systemImage: "cpu")
                }
                .tag(SettingsSection.engine)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsSection.about)
        }
        .frame(width: 500, height: 340)
        .background(BourbonColors.background)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    
    @AppStorage("bourbon.launchAtLogin")    var launchAtLogin    = false
    @AppStorage("bourbon.showDockIcon")     var showDockIcon     = true
    @AppStorage("bourbon.defaultEngine")   var defaultEngine    = "gptk"
    
    var body: some View {
        Form {
            Section("Behaviour") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show in Dock", isOn: $showDockIcon)
            }
            
            Section("Defaults") {
                Picker("Default Engine", selection: $defaultEngine) {
                    Text("Game Porting Toolkit").tag("gptk")
                    Text("Wine").tag("wine")
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(BourbonColors.background)
    }
}

// MARK: - Engine Settings
struct EngineSettingsView: View {
    
    @State private var gptkVersion = "Checking..."
    @State private var wineVersion = "Checking..."
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Status
            HStack {
                Text("Engine Status")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                StatusBadge(status: appState.engineStatus)
            }
            
            // Versions
            VStack(spacing: 8) {
                HStack {
                    Text("Game Porting Toolkit")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(gptkVersion)
                        .foregroundStyle(BourbonColors.textSecondary)
                        .font(.caption)
                }
                Divider().background(BourbonColors.border)
                HStack {
                    Text("Wine")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(wineVersion)
                        .foregroundStyle(BourbonColors.textSecondary)
                        .font(.caption)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(BourbonColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(BourbonColors.border, lineWidth: 1)
                    )
            )
            
            BourbonButton(
                title: "Refresh",
                icon: "arrow.clockwise",
                style: .secondary
            ) {
                Task { await checkVersions() }
            }
            
            Spacer()
        }
        .padding(24)
        .background(BourbonColors.background)
        .task { await checkVersions() }
    }
    
    private func checkVersions() async {
        let manager = EngineManager.shared
        
        if let gptk = await manager.findGPTK() {
            let engine  = BourbonEngine(type: .gptk, binaryURL: gptk)
            gptkVersion = await manager.version(of: engine)
        } else {
            gptkVersion = "Not installed"
        }
        
        if let wine = manager.findWine() {
            let engine  = BourbonEngine(type: .wine, binaryURL: wine)
            wineVersion = await manager.version(of: engine)
        } else {
            wineVersion = "Not installed"
        }
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(BourbonColors.accent)
            
            Text("Bourbon")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundStyle(BourbonColors.textSecondary)
            
            Text("Run Windows games and software on macOS\nusing Wine and Apple's Game Porting Toolkit")
                .font(.caption)
                .foregroundStyle(BourbonColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(24)
        .background(BourbonColors.background)
    }
}
