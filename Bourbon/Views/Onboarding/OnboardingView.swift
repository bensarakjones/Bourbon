import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var currentStep: Step = .welcome
    
    enum Step {
        case welcome
        case setup
    }
    
    var body: some View {
        ZStack {
            BourbonColors.background.ignoresSafeArea()
            
            switch currentStep {
            case .welcome:
                WelcomeStep {
                    withAnimation(.easeInOut) {
                        currentStep = .setup
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .setup:
                SetupStep {
                    appState.completeOnboarding()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    BourbonColors.accent.opacity(0.25),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    BourbonColors.accentLight,
                                    BourbonColors.accent
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Bourbon")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Run Windows games and apps on your Mac")
                        .font(.title3)
                        .foregroundStyle(BourbonColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                OnboardingFeatureRow(
                    icon: "gamecontroller.fill",
                    title: "Game Porting Toolkit",
                    description: "Apple's DirectX to Metal translation"
                )
                OnboardingFeatureRow(
                    icon: "cpu.fill",
                    title: "Apple Silicon Optimized",
                    description: "ESYNC and MSYNC for maximum performance"
                )
                OnboardingFeatureRow(
                    icon: "cylinder.split.1x2.fill",
                    title: "Bottle Management",
                    description: "Isolated environments per app or game"
                )
            }
            .padding(.horizontal, 60)
            
            Spacer()
            
            BourbonButton(
                title: "Get Started",
                icon: "arrow.right.circle.fill",
                style: .primary,
                action: onContinue
            )
            .scaleEffect(1.1)
            
            Spacer()
                .frame(height: 60)
        }
    }
}

// MARK: - Setup Step
struct SetupStep: View {
    
    let onComplete: () -> Void
    
    @State private var dependencies: [Dependency] = [
        Dependency(
            id: "rosetta",
            name: "Rosetta 2",
            description: "Required to run Intel-based Wine on Apple Silicon",
            checkCommand: ["arch", "-x86_64", "echo", "ok"],
            installCommand: ["softwareupdate", "--install-rosetta", "--agree-to-license"],
            isRequired: true
        ),
        Dependency(
            id: "homebrew",
            name: "Homebrew",
            description: "Package manager needed to install Wine",
            checkCommand: ["which", "brew"],
            installCommand: [],  // Special case - handled separately
            isRequired: true
        ),
        Dependency(
            id: "wine",
            name: "Wine Stable",
            description: "Runs Windows applications on macOS",
            checkCommand: ["which", "wine"],
            installCommand: ["brew", "install", "--cask", "wine-stable"],
            isRequired: true
        ),
        Dependency(
            id: "winetricks",
            name: "Winetricks",
            description: "Installs Windows components like .NET and DirectX",
            checkCommand: ["which", "winetricks"],
            installCommand: ["brew", "install", "winetricks"],
            isRequired: false
        )
    ]
    
    @State private var isCheckingAll   = false
    @State private var isInstallingAll = false
    @State private var log             = ""
    @State private var showLog         = false
    
    var allRequiredInstalled: Bool {
        dependencies
            .filter { $0.isRequired }
            .allSatisfy { $0.status == .installed }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Header
            VStack(spacing: 8) {
                Text("Setup")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                Text("Bourbon needs a few tools to run Windows apps")
                    .font(.subheadline)
                    .foregroundStyle(BourbonColors.textSecondary)
            }
            .padding(.top, 50)
            .padding(.bottom, 30)
            
            // Dependency cards
            VStack(spacing: 8) {
                ForEach($dependencies) { $dep in
                    DependencyCard(dependency: $dep)
                }
            }
            .padding(.horizontal, 60)
            
            // Log toggle
            if !log.isEmpty {
                Button(action: { showLog.toggle() }) {
                    HStack {
                        Image(systemName: showLog
                              ? "chevron.up"
                              : "chevron.down")
                        Text(showLog ? "Hide Log" : "Show Log")
                    }
                    .font(.caption)
                    .foregroundStyle(BourbonColors.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            
            // Log view
            if showLog && !log.isEmpty {
                ScrollView {
                    Text(log)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(height: 100)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                
                // Check all
                BourbonButton(
                    title: isCheckingAll ? "Checking..." : "Check All",
                    icon: "arrow.clockwise",
                    style: .secondary,
                    isLoading: isCheckingAll
                ) {
                    Task { await checkAll() }
                }
                
                // Install all missing
                if !allRequiredInstalled {
                    BourbonButton(
                        title: isInstallingAll
                            ? "Installing..."
                            : "Install All",
                        icon: isInstallingAll ? nil : "arrow.down.circle.fill",
                        style: .primary,
                        isLoading: isInstallingAll
                    ) {
                        Task { await installAll() }
                    }
                }
                
                // Continue
                BourbonButton(
                    title: allRequiredInstalled
                        ? "Continue"
                        : "Skip for now",
                    icon: allRequiredInstalled
                        ? "checkmark.circle.fill"
                        : "arrow.right",
                    style: allRequiredInstalled ? .primary : .ghost,
                    action: onComplete
                )
            }
            .padding(.bottom, 50)
        }
        .task { await checkAll() }
    }
    
    // MARK: - Check all dependencies
    private func checkAll() async {
        isCheckingAll = true
        for i in dependencies.indices {
            dependencies[i].status = .checking
            let found = await checkDependency(dependencies[i])
            dependencies[i].status = found ? .installed : .notInstalled
        }
        isCheckingAll = false
    }
    
    // MARK: - Install all missing
    private func installAll() async {
        isInstallingAll = true
        
        for i in dependencies.indices {
            guard dependencies[i].status == .notInstalled else { continue }
            
            dependencies[i].status = .installing
            
            // Special case for Homebrew
            if dependencies[i].id == "homebrew" {
                await installHomebrew(index: i)
                continue
            }
            
            let success = await installDependency(
                dependencies[i],
                index: i
            )
            dependencies[i].status = success ? .installed : .failed
        }
        
        isInstallingAll = false
        await checkAll()
    }
    
    // MARK: - Check single dependency
    private func checkDependency(_ dep: Dependency) async -> Bool {
        guard !dep.checkCommand.isEmpty else { return false }
        let result = try? await ProcessRunner.run(dep.checkCommand)
        return result?.succeeded ?? false
    }
    
    // MARK: - Install single dependency
    private func installDependency(
        _ dep: Dependency,
        index: Int
    ) async -> Bool {
        guard !dep.installCommand.isEmpty else { return false }
        
        let code = try? await ProcessRunner.runStreaming(
            dep.installCommand,
            onOutput: { output in
                self.log += output
            }
        )
        return code == 0
    }
    
    // MARK: - Install Homebrew (special case)
    private func installHomebrew(index: Int) async {
        let script = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        
        let code = try? await ProcessRunner.runStreaming(
            ["/bin/bash", "-c", script],
            onOutput: { output in
                self.log += output
            }
        )
        dependencies[index].status = code == 0 ? .installed : .failed
    }
}

// MARK: - Dependency Card
struct DependencyCard: View {
    
    @Binding var dependency: Dependency
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Status icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 38, height: 38)
                
                switch dependency.status {
                case .checking, .installing:
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                default:
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(dependency.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    if !dependency.isRequired {
                        Text("Optional")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(BourbonColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                Text(dependency.description)
                    .font(.caption)
                    .foregroundStyle(BourbonColors.textSecondary)
            }
            
            Spacer()
            
            // Status badge
            Text(dependency.status.label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(statusTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusBadgeBackground)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(BourbonColors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(BourbonColors.border, lineWidth: 1)
                )
        )
    }
    
    private var iconName: String {
        switch dependency.status {
        case .installed:    return "checkmark"
        case .notInstalled: return "xmark"
        case .failed:       return "exclamationmark"
        default:            return "circle"
        }
    }
    
    private var iconColor: Color {
        switch dependency.status {
        case .installed:    return .green
        case .notInstalled: return .red
        case .failed:       return .orange
        default:            return .gray
        }
    }
    
    private var iconBackground: Color {
        switch dependency.status {
        case .installed:              return .green.opacity(0.15)
        case .notInstalled, .failed:  return .red.opacity(0.15)
        case .checking, .installing:  return BourbonColors.accent.opacity(0.15)
        default:                      return Color.white.opacity(0.08)
        }
    }
    
    private var statusTextColor: Color {
        switch dependency.status {
        case .installed:    return .green
        case .notInstalled: return .red
        case .failed:       return .orange
        case .installing,
             .checking:     return BourbonColors.accentLight
        default:            return BourbonColors.textSecondary
        }
    }
    
    private var statusBadgeBackground: Color {
        switch dependency.status {
        case .installed:    return .green.opacity(0.12)
        case .notInstalled: return .red.opacity(0.12)
        case .failed:       return .orange.opacity(0.12)
        default:            return Color.white.opacity(0.06)
        }
    }
}

// MARK: - Dependency Model
struct Dependency: Identifiable {
    let id:             String
    let name:           String
    let description:    String
    let checkCommand:   [String]
    let installCommand: [String]
    let isRequired:     Bool
    var status:         Status = .unknown
    
    enum Status: Equatable {
        case unknown
        case checking
        case installed
        case notInstalled
        case installing
        case failed
        
        var label: String {
            switch self {
            case .unknown:       return "Unknown"
            case .checking:      return "Checking..."
            case .installed:     return "Installed"
            case .notInstalled:  return "Not Found"
            case .installing:    return "Installing..."
            case .failed:        return "Failed"
            }
        }
    }
}

// MARK: - Feature Row
struct OnboardingFeatureRow: View {
    let icon:        String
    let title:       String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(BourbonColors.accent.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(BourbonColors.accentLight)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(BourbonColors.textSecondary)
            }
            
            Spacer()
        }
    }
}
