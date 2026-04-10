import SwiftUI

struct ModelCard: View {
    let model: AIModelConfig
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            WaveCard(style: .standard, padding: Wave.spacing.s16) {
                VStack(alignment: .leading, spacing: Wave.spacing.s12) {
                    // Top row: provider icon + active badge
                    HStack(alignment: .center, spacing: Wave.spacing.s8) {
                        ProviderIcon(model: model, size: 20)
                            .frame(width: 32, height: 32)
                            .background(model.providerColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r8))

                        Spacer()

                        if isActive {
                            WavePillBadge("Active", tone: .info)
                        }
                    }

                    // Middle: title + description
                    VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                        Text(model.name)
                            .waveFont(Wave.font.cardTitle)
                            .foregroundStyle(Wave.colors.textPrimary)
                            .lineLimit(2)

                        Text(model.description)
                            .waveFont(Wave.font.body)
                            .foregroundStyle(Wave.colors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    // Bottom: configure ghost link
                    Text("Configure")
                        .waveFont(Wave.font.bodyMedium)
                        .foregroundStyle(Wave.colors.accent)
                }
                .frame(width: 208, height: 168, alignment: .leading)
            }
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(isActive ? Wave.colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
