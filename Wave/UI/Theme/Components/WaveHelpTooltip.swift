import SwiftUI

struct WaveHelpTooltip: View {
    let helpText: String
    @State private var isShowing = false

    var body: some View {
        Button(action: { isShowing.toggle() }) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Wave.colors.textTertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowing) {
            Text(helpText)
                .waveFont(Wave.font.captionLight)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(Wave.spacing.s12)
                .frame(maxWidth: 260)
        }
    }
}
