import SwiftUI

struct ModesView: View {
    @Bindable var appState: AppState
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
                VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                    Text("Rewrite Level")
                        .font(.system(size: 20, weight: .bold))

                    Text("Choose how aggressively Wave cleans up your dictated text.")
                        .font(.system(size: 13))
                        .foregroundStyle(WaveTheme.textSecondary)
                }

                VStack(spacing: WaveTheme.spacingSM) {
                    ForEach(Array(RewriteLevel.allCases.enumerated()), id: \.element) { index, level in
                        RewriteLevelCard(
                            level: level,
                            isSelected: appState.selectedRewriteLevel == level,
                            onSelect: { appState.selectedRewriteLevel = level }
                        )
                    }
                }
            }
            .padding(WaveTheme.spacingXL)
        }
        .onChange(of: appState.selectedRewriteLevel) { appState.saveToPreferences() }
    }
}

struct RewriteLevelCard: View {
    let level: RewriteLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: WaveTheme.spacingMD) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? WaveTheme.accent : WaveTheme.textTertiary)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WaveTheme.textPrimary)
                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textSecondary)
                }

                Spacer()
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: WaveTheme.radiusMD)
                .stroke(isSelected ? WaveTheme.accent : .clear, lineWidth: 1.5)
        )
    }
}
