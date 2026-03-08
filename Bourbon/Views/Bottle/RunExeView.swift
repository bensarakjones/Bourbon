import SwiftUI

struct RunExeView: View {
    
    let bottle:        Bottle
    @ObservedObject var bottleManager: BottleManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedURL:  URL?    = nil
    @State private var programName:  String  = ""
    @State private var isLaunching:  Bool    = false
    @State private var saveToLib:    Bool    = true
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Run EXE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("in \(bottle.name)")
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
            
            Divider().background(BourbonColors.border)
            
            VStack(spacing: 20) {
                
                // File picker
                VStack(alignment: .leading, spacing: 8) {
                    BourbonSectionHeader(title: "EXE File")
                    
                    Button(action: pickFile) {
                        HStack {
                            Image(systemName: selectedURL == nil
                                  ? "doc.badge.plus"
                                  : "doc.fill")
                                .foregroundStyle(BourbonColors.accent)
                            
                            Text(selectedURL?.lastPathComponent
                                 ?? "Click to choose an EXE file...")
                                .foregroundStyle(
                                    selectedURL == nil
                                    ? BourbonColors.textSecondary
                                    : .white
                                )
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedURL == nil
                                    ? BourbonColors.border
                                    : BourbonColors.accent.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Program name
                if selectedURL != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        BourbonSectionHeader(title: "Program Name")
                        
                        TextField("Name", text: $programName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(BourbonColors.border, lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                    }
                    
                    // Save to library toggle
                    BourbonToggleRow(
                        title: "Save to Library",
                        description: "Add this program to the bottle's program list",
                        isOn: $saveToLib
                    )
                }
            }
            .padding(24)
            
            Spacer()
            
            Divider().background(BourbonColors.border)
            
            // MARK: - Footer
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    BourbonButton(
                        title: "Cancel",
                        style: .secondary
                    ) {
                        dismiss()
                    }
                    
                    BourbonButton(
                        title: isLaunching ? "Launching..." : "Launch",
                        icon: isLaunching ? nil : "play.fill",
                        style: .primary,
                        isLoading: isLaunching,
                        isDisabled: selectedURL == nil
                    ) {
                        Task { await launch() }
                    }
                }
            }
            .padding(24)
        }
        .background(BourbonColors.background)
        .frame(width: 420, height: 380)
    }
    
    private func pickFile() {
        let panel = NSOpenPanel()
        panel.title = "Choose an EXE file"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["exe"]
        
        if panel.runModal() == .OK {
            selectedURL = panel.url
            if let url = panel.url {
                programName = url
                    .deletingPathExtension()
                    .lastPathComponent
            }
        }
    }
    
    private func launch() async {
        guard let url = selectedURL else { return }
        isLaunching = true
        
        var program = Program(name: programName, executableURL: url)
        
        if saveToLib {
            bottleManager.addProgram(program, to: bottle)
        }
        
        await bottleManager.launch(program, in: bottle)
        isLaunching = false
        dismiss()
    }
}
