import SwiftUI

struct DeepCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.01), radius: 3,  y: 1)
            .shadow(color: .black.opacity(0.02), radius: 7,  y: 3)
            .shadow(color: .black.opacity(0.02), radius: 15, y: 7)
            .shadow(color: .black.opacity(0.04), radius: 28, y: 14)
            .shadow(color: .black.opacity(0.05), radius: 52, y: 23)
    }
}

extension View {
    func deepCardShadow() -> some View { modifier(DeepCardShadow()) }
}
