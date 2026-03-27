import Foundation
import Observation

@Observable
final class RecordingTimeLimiter: @unchecked Sendable {
    private(set) var elapsedSeconds: TimeInterval = 0
    private(set) var hasShownWarning = false
    private(set) var hasShownNudge = false

    private var timer: Timer?
    private let warningThreshold: TimeInterval = 120  // 2 minutes
    private let nudgeThreshold: TimeInterval = 300    // 5 minutes

    var onWarning: (() -> Void)?
    var onNudge: (() -> Void)?

    func start() {
        reset()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1

            if self.elapsedSeconds >= self.warningThreshold && !self.hasShownWarning {
                self.hasShownWarning = true
                self.onWarning?()
            }

            if self.elapsedSeconds >= self.nudgeThreshold && !self.hasShownNudge {
                self.hasShownNudge = true
                self.onNudge?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        elapsedSeconds = 0
        hasShownWarning = false
        hasShownNudge = false
    }

    var formattedDuration: String {
        let minutes = Int(elapsedSeconds) / 60
        let seconds = Int(elapsedSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
