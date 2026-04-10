import SwiftUI

struct WaveDottedSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Wave.colors.surfaceSecondary)
                    .frame(height: 4)
                Capsule()
                    .fill(Wave.colors.accent)
                    .frame(width: fillWidth(total: geo.size.width), height: 4)
                Circle()
                    .fill(Wave.colors.surfacePrimary)
                    .overlay(Circle().stroke(Wave.colors.accent, lineWidth: 2))
                    .softCardShadow()
                    .frame(width: 14, height: 14)
                    .offset(x: fillWidth(total: geo.size.width) - 7)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let pct = min(max(gesture.location.x / geo.size.width, 0), 1)
                                let raw = range.lowerBound + pct * (range.upperBound - range.lowerBound)
                                let stepped = (raw / step).rounded() * step
                                value = stepped
                            }
                    )
            }
            .frame(height: 14)
        }
        .frame(height: 14)
    }

    private func fillWidth(total: CGFloat) -> CGFloat {
        let pct = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(pct) * total
    }
}
