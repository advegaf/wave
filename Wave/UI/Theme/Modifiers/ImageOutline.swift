import SwiftUI

/// 1px hairline outline for raster/vector imagery (app icons, provider logos,
/// thumbnails). Uses `Wave.colors.border` — pure black 0.10 in light, pure
/// white 0.08 in dark — so it never reads as a tinted dirt edge.
/// `strokeBorder` keeps the line inside the clip to avoid fractional AA on the
/// outer edge.
struct ImageOutline: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(Wave.colors.border, lineWidth: 1)
        )
    }
}

extension View {
    func imageOutline(radius: CGFloat) -> some View {
        modifier(ImageOutline(radius: radius))
    }
}
