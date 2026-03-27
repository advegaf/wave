import SwiftUI

struct SidebarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            List(SidebarItem.allCases, selection: $appState.selectedSidebarItem) { item in
                Label {
                    Text(item.rawValue)
                } icon: {
                    Image(systemName: item.iconName)
                        .foregroundStyle(item.iconColor)
                }
                .tag(item)
            }
            .listStyle(.sidebar)

            // Footer branding
            Text("Wave v0.1.0")
                .font(.system(size: 11))
                .foregroundStyle(WaveTheme.textTertiary)
                .padding(.bottom, WaveTheme.spacingMD)
        }
        .frame(minWidth: WaveTheme.sidebarWidth)
    }
}
