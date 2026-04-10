import SwiftUI

enum WaveButtonStyleKind { case primary, secondary, ghost }

struct WaveButton: View {
    let title: String
    let icon: String?
    let kind: WaveButtonStyleKind
    let action: () -> Void

    init(_ title: String, icon: String? = nil, kind: WaveButtonStyleKind = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.kind = kind
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Wave.spacing.s6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .waveFont(Wave.font.nav)
        }
        .buttonStyle(WaveButtonInternalStyle(kind: kind))
    }
}

private struct WaveButtonInternalStyle: ButtonStyle {
    let kind: WaveButtonStyleKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical,   Wave.spacing.s8)
            .background(background(pressed: configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
            .overlay(borderOverlay)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    @ViewBuilder private func background(pressed: Bool) -> some View {
        switch kind {
        case .primary:   (pressed ? Wave.colors.accentHover : Wave.colors.accent)
        case .secondary: Wave.colors.surfaceSecondary
        case .ghost:     Color.clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary:   return .white
        case .secondary: return Wave.colors.textPrimary
        case .ghost:     return Wave.colors.accent
        }
    }

    @ViewBuilder private var borderOverlay: some View {
        switch kind {
        case .secondary:
            RoundedRectangle(cornerRadius: Wave.radius.r4)
                .stroke(Wave.colors.border, lineWidth: 1)
        case .primary, .ghost:
            EmptyView()
        }
    }
}
