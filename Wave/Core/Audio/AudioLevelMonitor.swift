import Foundation
import Observation

@Observable
final class AudioLevelMonitor: @unchecked Sendable {
    private(set) var currentLevel: Float = 0.0
    private(set) var smoothedLevel: Float = 0.0

    private let smoothingFactor: Float = 0.3
    private let decayRate: Float = 0.05

    func update(with level: Float) {
        currentLevel = level
        // Exponential smoothing: rise fast, fall slow
        if level > smoothedLevel {
            smoothedLevel = smoothedLevel + smoothingFactor * (level - smoothedLevel)
        } else {
            smoothedLevel = max(0, smoothedLevel - decayRate)
        }
    }

    func reset() {
        currentLevel = 0
        smoothedLevel = 0
    }
}
