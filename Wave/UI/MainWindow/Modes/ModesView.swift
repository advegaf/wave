import SwiftUI

struct ModesView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                WaveSectionHeader(
                    "Rewrite Mode",
                    subtitle: "Choose if and how Wave cleans up your dictated text."
                )

                VStack(spacing: Wave.spacing.s12) {
                    ForEach(RewriteLevel.allCases, id: \.self) { level in
                        ModeCard(
                            level: level,
                            isSelected: appState.selectedRewriteLevel == level
                        ) {
                            appState.selectedRewriteLevel = level
                            appState.saveToPreferences()
                        }
                    }
                }
            }
            .padding(Wave.spacing.s32)
        }
    }
}

// MARK: - Private

private struct ModeCard: View {
    let level: RewriteLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Wave.spacing.s16) {
                VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                    Text(level.rawValue)
                        .waveFont(Wave.font.cardTitle)
                        .foregroundStyle(Wave.colors.textPrimary)
                    Text(level.description)
                        .waveFont(Wave.font.body)
                        .foregroundStyle(Wave.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textTertiary)
                    .imageScale(.large)
                    .waveFont(Wave.font.sectionHeading)
            }
            .padding(Wave.spacing.s20)
            .background(
                isSelected
                    ? Wave.colors.accent.opacity(0.08)
                    : Wave.colors.surfacePrimary
            )
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r12))
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(
                        isSelected ? Wave.colors.accent : Wave.colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .softCardShadow()
        }
        .buttonStyle(.plain)
    }
}
