import SwiftUI

// MARK: - Colors
enum BourbonColors {
    static let background    = Color(hex: "1A1008")
    static let sidebar       = Color(hex: "120A04")
    static let card          = Color(hex: "231508")
    static let accent        = Color(hex: "C47B2B")
    static let accentLight   = Color(hex: "E8A84B")
    static let border        = Color.white.opacity(0.08)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.5)
}

// MARK: - Button
struct BourbonButton: View {
    
    enum Style {
        case primary
        case secondary
        case ghost
        case destructive
    }
    
    let title:      String
    var icon:       String? = nil
    var style:      Style   = .primary
    var isLoading:  Bool    = false
    var isDisabled: Bool    = false
    let action:     () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.65)
                        .tint(foregroundColor)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:     return BourbonColors.accent
        case .secondary:   return Color.white.opacity(0.08)
        case .ghost:       return .clear
        case .destructive: return Color.red.opacity(0.15)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .white
        case .ghost:       return BourbonColors.accentLight
        case .destructive: return .red
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:     return BourbonColors.accentLight.opacity(0.4)
        case .secondary:   return Color.white.opacity(0.1)
        case .ghost:       return .clear
        case .destructive: return Color.red.opacity(0.3)
        }
    }
}

// MARK: - Card
struct BourbonCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(BourbonColors.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BourbonColors.border, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Section Header
struct BourbonSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(BourbonColors.textSecondary)
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Toggle Row
struct BourbonToggleRow: View {
    let title:       String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(BourbonColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(BourbonColors.accent)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: AppState.EngineStatus
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.caption2)
                .foregroundStyle(BourbonColors.textSecondary)
        }
    }
    
    private var dotColor: Color {
        switch status {
        case .ready:      return .green
        case .installing: return .yellow
        case .error:      return .red
        case .checking:   return .orange
        default:          return .gray
        }
    }
}

// MARK: - Color from Hex
extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if h.count == 6 { h = "FF" + h }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            .sRGB,
            red:     Double((val >> 16) & 0xFF) / 255,
            green:   Double((val >> 8)  & 0xFF) / 255,
            blue:    Double( val        & 0xFF) / 255,
            opacity: Double((val >> 24) & 0xFF) / 255
        )
    }
}
