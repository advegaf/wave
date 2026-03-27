import SwiftUI

struct Curve: Equatable, Sendable {
    var amplitude: CGFloat
    var frequency: CGFloat
    var time: CGFloat

    static func random() -> Curve {
        Curve(
            amplitude: .random(in: 0.1...1.0),
            frequency: .random(in: 0.6...0.9),
            time: .random(in: -1.0...4.0)
        )
    }

    static var zero: Curve {
        Curve(amplitude: 0, frequency: 0.75, time: 1.5)
    }
}

extension Curve: Animatable {
    typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat>

    var animatableData: AnimatableData {
        get { AnimatablePair(AnimatablePair(amplitude, frequency), time) }
        set {
            amplitude = newValue.first.first
            frequency = newValue.first.second
            time = newValue.second
        }
    }
}
