import SwiftUI

struct NewBottleView: View {
    
    @ObservedObject var bottleManager: BottleManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name:           String                 = ""
    @State private var windowsVersion: Bottle.WindowsVersion = .windows10
    @State private var engineType:     Bottle.EngineType     = .gptk
    @State private var isCreating:     Bool                  = false
    @State private var showError:      Bool                  = false
    @State private var errorMessage:   String                = ""
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Bottle")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Set up a Windows environment")
                        .font(.subheadline)
                        .foregroundStyle(BourbonColors.textSecondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(BourbonColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
                .background(BourbonColors.border)
            
            // MARK: - Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        BourbonSectionHeader(title: "Bottle Name")
                        
                        TextField("e.g. Steam Games, Office Apps...", text: $name)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        name.isEmpty
                                        ? BourbonColors.border
                                        : BourbonColors.accent.opacity(0.5),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                    }
                    
                    // Windows Version
                    VStack(alignment: .leading, spacing: 8) {
                        BourbonSectionHeader(title: "Windows Version")
                        
                        VStack(spacing: 4) {
                            ForEach(Bottle.WindowsVersion.allCases, id: \.self) { version in
                                VersionRow(
                                    version: version,
                                    isSelected: windowsVersion == version
                                ) {
                                    windowsVersion = version
                                }
                            }
                        }
                    }
                    
                    // Engine
                    VStack(alignment: .leading, spacing: 8) {
                        BourbonSectionHeader(title: "Engine")
                        
                        VStack(spacing: 4) {
                            EngineRow(
                                title: "Game Porting Toolkit",
                                subtitle: "Best for games. Uses Apple's D3D→Metal layer.",
                                icon: "gamecontroller.fill",
                                isSelected: engineType == .gptk
                            ) {
                                engineType = .gptk
                            }
                            
                            EngineRow(
                                title: "Wine",
                                subtitle: "Great for general Windows software.",
                                icon: "app.gift.fill",
                                isSelected: engineType == .wine
                            ) {
                                engineType = .wine
                            }
                        }
                    }
                }
                .padding(24)
            }
            
            Divider()
                .background(BourbonColors.border)
            
            // MARK: - Footer
            HStack {
                if isCreating {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Initializing bottle...")
                            .font(.caption)
                            .foregroundStyle(BourbonColors.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    BourbonButton(
                        title: "Cancel",
                        style: .secondary
                    ) {
                        dismiss()
                    }
                    
                    BourbonButton(
                        title: isCreating ? "Creating..." : "Create Bottle",
                        icon: isCreating ? nil : "plus.circle.fill",
                        style: .primary,
                        isLoading: isCreating,
                        isDisabled: !isValid
                    ) {
                        Task { await createBottle() }
                    }
                }
            }
            .padding(24)
        }
        .background(BourbonColors.background)
        .frame(width: 460, height: 580)
        .alert("Failed to Create Bottle", isPresented: $showError) {
            Button("OK") {
                bottleManager.clearError()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createBottle() async {
        isCreating = true
        bottleManager.clearError()
        
        await bottleManager.createBottle(
            name:           name,
            windowsVersion: windowsVersion,
            engineType:     engineType
        )
        
        isCreating = false
        
        if let error = bottleManager.error {
            errorMessage = error.localizedDescription
            showError    = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Version Row
struct VersionRow: View {
    let version:    Bottle.WindowsVersion
    let isSelected: Bool
    let onTap:      () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "desktopcomputer")
                    .frame(width: 20)
                    .foregroundStyle(
                        isSelected
                        ? BourbonColors.accentLight
                        : BourbonColors.textSecondary
                    )
                
                Text(version.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BourbonColors.accent)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? BourbonColors.accent.opacity(0.12)
                        : Color.white.opacity(0.04)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected
                                ? BourbonColors.accent.opacity(0.4)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Engine Row
struct EngineRow: View {
    let title:      String
    let subtitle:   String
    let icon:       String
    let isSelected: Bool
    let onTap:      () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected
                            ? BourbonColors.accent.opacity(0.2)
                            : Color.white.opacity(0.06)
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(
                            isSelected
                            ? BourbonColors.accentLight
                            : BourbonColors.textSecondary
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(BourbonColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BourbonColors.accent)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                        ? BourbonColors.accent.opacity(0.12)
                        : Color.white.opacity(0.04)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected
                                ? BourbonColors.accent.opacity(0.4)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
