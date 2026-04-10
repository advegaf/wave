import SwiftUI

struct WhisperBorder: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Wave.colors.border, lineWidth: 1)
        )
    }
}

extension View {
    func whisperBorder(radius: CGFloat = Wave.radius.r12) -> some View {
        modifier(WhisperBorder(radius: radius))
    }
}
