import SwiftUI

struct WaveSettingRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: Wave.spacing.s16) {
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, Wave.spacing.s8)
    }
}
