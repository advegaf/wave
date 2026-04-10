import SwiftUI

struct SidebarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Brand header
            HStack(spacing: Wave.spacing.s8) {
                Image(systemName: "waveform")
                    .foregroundStyle(Wave.colors.accent)
                    .waveFont(Wave.font.cardTitle)
                Text("Wave")
                    .waveFont(Wave.font.cardTitle)
                    .foregroundStyle(Wave.colors.textPrimary)
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical, Wave.spacing.s20)

            // MARK: Nav items
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(
                        item: item,
                        isSelected: appState.selectedSidebarItem == item
                    ) {
                        appState.selectedSidebarItem = item
                    }
                }
            }
            .padding(.horizontal, Wave.spacing.s8)

            Spacer()

            // MARK: Footer
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0")")
                .waveFont(Wave.font.micro)
                .foregroundStyle(Wave.colors.textTertiary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.bottom, Wave.spacing.s16)
        }
        .frame(minWidth: Wave.window.sidebarWidth)
    }
}

// MARK: - Sidebar Row

private struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Wave.spacing.s8) {
                Image(systemName: item.iconName)
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textSecondary)
                    .frame(width: 16, height: 16)

                Text(item.rawValue)
                    .waveFont(Wave.font.nav)
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Wave.spacing.s12)
            .padding(.vertical, Wave.spacing.s8)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r8))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            Wave.colors.accent.opacity(0.12)
        } else if isHovering {
            Wave.colors.surfaceHover
        } else {
            Color.clear
        }
    }
}
