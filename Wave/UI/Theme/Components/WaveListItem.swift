import SwiftUI

struct WaveListItem<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let leading: String?
    let accessory: () -> Accessory
    let onTap: (() -> Void)?

    @State private var isHovering = false

    init(
        title: String,
        subtitle: String? = nil,
        leading: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.onTap = onTap
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: Wave.spacing.s12) {
            if let leading {
                Image(systemName: leading)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .frame(width: 16)
            }
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            accessory()
        }
        .padding(.horizontal, Wave.spacing.s12)
        .padding(.vertical, Wave.spacing.s10)
        .background(isHovering ? Wave.colors.surfaceHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { onTap?() }
    }
}

extension Wave.spacing {
    static let s10: CGFloat = 10
}
