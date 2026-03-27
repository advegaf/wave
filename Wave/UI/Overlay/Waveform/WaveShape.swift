import SwiftUI

struct WaveShape: Shape {
    var wave: SiriWave

    var animatableData: SiriWave.AnimatableData {
        get { wave.animatableData }
        set { wave.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        let midY = rect.midY
        let xPoints = Array(stride(from: -midX, to: midX, by: 1))
        var heights = [CGFloat](repeating: 0, count: xPoints.count)

        for i in 0..<wave.curves.count {
            let curve = wave.curves[i]
            let amplitude = curve.amplitude * midY * wave.power

            for (j, graphX) in xPoints.enumerated() {
                let x = graphX / (midX / 9)
                let y = attenuate(x: x, amplitude: amplitude, frequency: curve.frequency, time: curve.time)
                heights[j] = max(heights[j], y)
            }
        }

        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))

        // Top half (above center)
        for (j, graphX) in xPoints.enumerated() {
            path.addLine(to: CGPoint(x: midX + graphX, y: midY - heights[j]))
        }

        // Bottom half (below center, reversed)
        for (j, graphX) in xPoints.enumerated().reversed() {
            path.addLine(to: CGPoint(x: midX + graphX, y: midY + heights[j]))
        }

        path.closeSubpath()
        return path
    }

    private func attenuate(x: CGFloat, amplitude: CGFloat, frequency: CGFloat, time: CGFloat) -> CGFloat {
        let sine = amplitude * sin((frequency * x) - time)
        let K: CGFloat = 4
        let globalAmplitude = pow(K / (K + pow(x, 2)), K)
        return abs(sine * globalAmplitude)
    }
}
