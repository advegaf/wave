import SwiftUI

struct SiriWave: Equatable, Sendable {
    var power: CGFloat
    var curves: [Curve]

    init(power: CGFloat) {
        self.power = power
        self.curves = (0..<4).map { _ in
            power > 0.01 ? Curve.random() : Curve.zero
        }
    }
}

extension SiriWave: Animatable {
    typealias AnimatableData = AnimatablePair<
        AnimatablePair<Curve.AnimatableData, Curve.AnimatableData>,
        AnimatablePair<Curve.AnimatableData, AnimatablePair<Curve.AnimatableData, CGFloat>>
    >

    var animatableData: AnimatableData {
        get {
            AnimatablePair(
                AnimatablePair(curves[0].animatableData, curves[1].animatableData),
                AnimatablePair(curves[2].animatableData, AnimatablePair(curves[3].animatableData, power))
            )
        }
        set {
            curves[0].animatableData = newValue.first.first
            curves[1].animatableData = newValue.first.second
            curves[2].animatableData = newValue.second.first
            curves[3].animatableData = newValue.second.second.first
            power = newValue.second.second.second
        }
    }
}
