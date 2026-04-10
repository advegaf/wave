import SwiftUI

struct SoftCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.04),  radius: 18,   y: 4)
            .shadow(color: .black.opacity(0.027), radius: 7.85, y: 2.025)
            .shadow(color: .black.opacity(0.02),  radius: 2.93, y: 0.8)
            .shadow(color: .black.opacity(0.01),  radius: 1.04, y: 0.175)
    }
}

extension View {
    func softCardShadow() -> some View { modifier(SoftCardShadow()) }
}
