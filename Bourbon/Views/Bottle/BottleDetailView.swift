import SwiftUI

struct BottleDetailView: View {
    
    @State var bottle:          Bottle
    @ObservedObject var bottleManager: BottleManager
    @State private var selectedTab    = BottleTab.programs
    @State private var showRunExe     = false
    @State private var launchLog      = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            BottleHeaderView(bottle: bottle) {
                showRunExe = true
            } onOpenCDrive: {
                NSWorkspace.shared.open(bottle.cDrivePath)
            }
            
            // MARK: - Tab Bar
            BottleTabBar(selectedTab: $selectedTab)
            
            Divider()
                .background(BourbonColors.border)
            
            // MARK: - Tab Content
            Group {
                switch selectedTab {
                case .programs:
                    ProgramsView(
                        bottle: $bottle,
                        bottleManager: bottleManager
                    )
                case .settings:
                    BottleSettingsView(
                        bottle: $bottle,
                        bottleManager: bottleManager
                    )
                case .logs:
                    LogsView(log: $launchLog)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BourbonColors.background)
        .sheet(isPresented: $showRunExe) {
            RunExeView(bottle: bottle, bottleManager: bottleManager)
        }
        // Keep bottle in sync if bottleManager updates it
        .onChange(of: bottleManager.bottles) { bottles in
            if let updated = bottles.first(where: { (b: Bottle) -> Bool in
                b.id == bottle.id
            }) {
                bottle = updated
            }
        }
    }
    
    enum BottleTab: String, CaseIterable {
        case programs = "Programs"
        case settings = "Settings"
        case logs     = "Logs"
        
        var icon: String {
            switch self {
            case .programs: return "square.grid.2x2"
            case .settings: return "gearshape"
            case .logs:     return "terminal"
            }
        }
    }
}

// MARK: - Header
struct BottleHeaderView: View {
    let bottle:       Bottle
    let onRunExe:     () -> Void
    let onOpenCDrive: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            
            // Bottle icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                BourbonColors.accent,
                                BourbonColors.accent.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "cylinder.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            
            // Name and info
            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack(spacing: 12) {
                    Label(
                        bottle.windowsVersion.displayName,
                        systemImage: "desktopcomputer"
                    )
                    Label(
                        bottle.engineType.displayName,
                        systemImage: "cpu"
                    )
                    Label(
                        bottle.programCount,
                        systemImage: "square.grid.2x2"
                    )
                }
                .font(.caption)
                .foregroundStyle(BourbonColors.textSecondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                BourbonButton(
                    title: "Open C: Drive",
                    icon: "folder",
                    style: .secondary,
                    action: onOpenCDrive
                )
                BourbonButton(
                    title: "Run EXE",
                    icon: "play.fill",
                    style: .primary,
                    action: onRunExe
                )
            }
        }
        .padding(20)
        .background(BourbonColors.card)
    }
}

// MARK: - Tab Bar
struct BottleTabBar: View {
    @Binding var selectedTab: BottleDetailView.BottleTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(BottleDetailView.BottleTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .foregroundStyle(
                        selectedTab == tab
                        ? BourbonColors.accentLight
                        : BourbonColors.textSecondary
                    )
                    .overlay(
                        Rectangle()
                            .fill(
                                selectedTab == tab
                                ? BourbonColors.accent
                                : .clear
                            )
                            .frame(height: 2),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: selectedTab)
            }
            Spacer()
        }
        .background(BourbonColors.card)
    }
}
