import SwiftUI

struct WaveChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .waveFont(Wave.font.caption)
                .padding(.horizontal, Wave.spacing.s12)
                .padding(.vertical, Wave.spacing.s6)
                .background(isSelected ? Wave.colors.accent.opacity(0.12) : Wave.colors.surfaceSecondary)
                .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Wave.colors.accent.opacity(0.4) : Wave.colors.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
