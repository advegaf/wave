import SwiftUI

struct ModelCard: View {
    let model: AIModelConfig
    let onTap: () -> Void
    @State private var isFavorite = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                HStack {
                    ProviderIcon(model: model)
                        .frame(width: 28, height: 28)
                        .background(model.providerColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))

                    Text(model.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : WaveTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Text(model.description)
                    .font(.system(size: 11))
                    .foregroundStyle(WaveTheme.textSecondary)
                    .lineLimit(3)
            }
            .frame(width: 220)
            .cardStyle()
        }
        .buttonStyle(.pressableCard)
    }
}
