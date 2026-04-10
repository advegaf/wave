import SwiftUI

struct WavePillBadge: View {
    let text: String
    let tone: Tone

    enum Tone { case info, success, warning, destructive, neutral }

    init(_ text: String, tone: Tone = .info) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text)
            .waveFont(Wave.font.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, Wave.spacing.s8)
            .padding(.vertical, Wave.spacing.s4)
            .background(background)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch tone {
        case .info:        return Wave.colors.badgeBlueBg
        case .success:     return Wave.colors.success.opacity(0.12)
        case .warning:     return Wave.colors.warning.opacity(0.12)
        case .destructive: return Wave.colors.destructive.opacity(0.12)
        case .neutral:     return Wave.colors.surfaceSecondary
        }
    }

    private var foreground: Color {
        switch tone {
        case .info:        return Wave.colors.badgeBlueText
        case .success:     return Wave.colors.success
        case .warning:     return Wave.colors.warning
        case .destructive: return Wave.colors.destructive
        case .neutral:     return Wave.colors.textSecondary
        }
    }
}
