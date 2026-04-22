import SwiftUI

/// Tactile press feedback per Wave's interaction polish: scale to 0.96 on press
/// with a fast easeOut so the recoil never feels exaggerated.
struct PressScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension View {
    /// Wrap a non-Button row/card so it gets the same press feedback as `WaveButton`,
    /// without each call site re-implementing press-state plumbing.
    func waveTappable(action: @escaping () -> Void) -> some View {
        Button(action: action) { self }
            .buttonStyle(PressScale())
    }
}
