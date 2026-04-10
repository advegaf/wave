import SwiftUI

struct WaveSectionHeader: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Wave.spacing.s12) {
            VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                Text(title)
                    .waveFont(Wave.font.sectionHeading)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.body)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}
