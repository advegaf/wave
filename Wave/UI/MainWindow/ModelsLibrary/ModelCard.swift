import SwiftUI

struct ModelCard: View {
    let model: AIModelConfig
    let isActive: Bool
    let onSelect: () -> Void
    let onConfigure: () -> Void

    var body: some View {
        Button(action: onSelect) {
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

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 16))
                    }

                    Button {
                        onConfigure()
                    } label: {
                        Image(systemName: "key.fill")
                            .foregroundStyle(WaveTheme.textTertiary)
                            .font(.system(size: 11))
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
            .overlay(
                RoundedRectangle(cornerRadius: WaveTheme.radiusMD)
                    .stroke(isActive ? .green.opacity(0.5) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
