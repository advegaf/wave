import SwiftUI

enum WaveCardStyle { case standard, hero }

struct WaveCard<Content: View>: View {
    let style: WaveCardStyle
    let padding: CGFloat
    let content: () -> Content

    init(style: WaveCardStyle = .standard, padding: CGFloat = Wave.spacing.s16, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return Wave.radius.r12
        case .hero:     return Wave.radius.r16
        }
    }

    var body: some View {
        content()
            .padding(padding)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .whisperBorder(radius: cornerRadius)
            .modifier(CardShadowModifier(style: style))
    }
}

private struct CardShadowModifier: ViewModifier {
    let style: WaveCardStyle
    func body(content: Content) -> some View {
        switch style {
        case .standard: content.softCardShadow()
        case .hero:     content.deepCardShadow()
        }
    }
}
