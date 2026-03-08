import SwiftUI

struct LogsView: View {
    
    @Binding var log: String
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Toolbar
            HStack {
                Text("Process Output")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BourbonColors.textSecondary)
                Spacer()
                if !log.isEmpty {
                    Button(action: { log = "" }) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                            .foregroundStyle(BourbonColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: copyLog) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(BourbonColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(BourbonColors.card)
            
            Divider().background(BourbonColors.border)
            
            // Log output
            ScrollViewReader { proxy in
                ScrollView {
                    if log.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "terminal")
                                .font(.largeTitle)
                                .foregroundStyle(BourbonColors.textSecondary.opacity(0.4))
                            Text("No output yet")
                                .font(.subheadline)
                                .foregroundStyle(BourbonColors.textSecondary)
                            Text("Logs will appear here when a program runs")
                                .font(.caption)
                                .foregroundStyle(BourbonColors.textSecondary.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        Text(log)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .id("bottom")
                    }
                }
                .onChange(of: log) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .background(Color.black.opacity(0.4))
        }
    }
    
    private func copyLog() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(log, forType: .string)
    }
}
