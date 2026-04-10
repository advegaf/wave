import SwiftUI

struct WaveEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let primaryAction: (title: String, action: () -> Void)?

    init(icon: String, title: String, subtitle: String? = nil, primaryAction: (title: String, action: () -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.primaryAction = primaryAction
    }

    var body: some View {
        VStack(spacing: Wave.spacing.s16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Wave.colors.textTertiary)
            Text(title)
                .waveFont(Wave.font.cardTitle)
                .foregroundStyle(Wave.colors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let primaryAction {
                WaveButton(primaryAction.title, kind: .primary, action: primaryAction.action)
                    .padding(.top, Wave.spacing.s8)
            }
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
