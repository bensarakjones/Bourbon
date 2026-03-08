import SwiftUI

struct ProgramsView: View {
    
    @Binding var bottle: Bottle
    @ObservedObject var bottleManager: BottleManager
    @State private var showRunExe    = false
    @State private var launchingId:  UUID? = nil
    @State private var isScanning:   Bool  = false
    @State private var scanMessage:  String = ""
    
    let columns = [
        GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Toolbar
            HStack(spacing: 8) {
                Spacer()
                
                if isScanning {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.6)
                        Text("Scanning...")
                            .font(.caption)
                            .foregroundStyle(BourbonColors.textSecondary)
                    }
                } else if !scanMessage.isEmpty {
                    Text(scanMessage)
                        .font(.caption)
                        .foregroundStyle(BourbonColors.textSecondary)
                }
                
                BourbonButton(
                    title: "Scan for Programs",
                    icon: "magnifyingglass",
                    style: .secondary,
                    isLoading: isScanning
                ) {
                    Task { await scanForPrograms() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(BourbonColors.card)
            
            Divider().background(BourbonColors.border)
            
            // MARK: - Content
            ScrollView {
                if bottle.programs.isEmpty {
                    EmptyProgramsView {
                        showRunExe = true
                    }
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(bottle.programs) { program in
                            ProgramCard(
                                program: program,
                                isLaunching: launchingId == program.id
                            ) {
                                Task { await launch(program) }
                            } onDelete: {
                                bottleManager.removeProgram(program, from: bottle)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(BourbonColors.background)
        .sheet(isPresented: $showRunExe) {
            RunExeView(bottle: bottle, bottleManager: bottleManager)
        }
    }
    
    private func launch(_ program: Program) async {
        launchingId = program.id
        await bottleManager.launch(program, in: bottle)
        launchingId = nil
    }
    
    private func scanForPrograms() async {
        isScanning  = true
        scanMessage = ""
        
        let found = await bottleManager.scanForPrograms(in: bottle)
        
        isScanning = false
        
        if found == 0 {
            scanMessage = "No new programs found"
        } else {
            scanMessage = "Found \(found) new program\(found == 1 ? "" : "s")"
        }
        
        // Clear the message after 3 seconds
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        scanMessage = ""
    }
}

// MARK: - Program Card
struct ProgramCard: View {
    
    let program:     Program
    let isLaunching: Bool
    let onLaunch:    () -> Void
    let onDelete:    () -> Void
    
    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 10) {
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 64, height: 64)
                    
                    if isLaunching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(nsImage: program.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }
                
                // Name
                Text(program.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                // Last played
                Text(program.formattedLastLaunched)
                    .font(.system(size: 10))
                    .foregroundStyle(BourbonColors.textSecondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(BourbonColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BourbonColors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Launch") { onLaunch() }
            Divider()
            Button("Remove", role: .destructive) { onDelete() }
        }
    }
}

// MARK: - Empty State
struct EmptyProgramsView: View {
    let onRunExe: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(BourbonColors.textSecondary.opacity(0.5))
            
            Text("No Programs Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            
            Text("Run an EXE file or use Scan for Programs\nto detect installed apps")
                .font(.subheadline)
                .foregroundStyle(BourbonColors.textSecondary)
                .multilineTextAlignment(.center)
            
            BourbonButton(
                title: "Run EXE File",
                icon: "play.fill",
                style: .primary,
                action: onRunExe
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}
