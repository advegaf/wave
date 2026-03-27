import Foundation
import Observation

@Observable
final class SilenceDetector {
    private(set) var isSilent = false
    private(set) var silenceDuration: TimeInterval = 0

    var timeoutSeconds: TimeInterval = 2.0  // Reduced from 3s for snappier response
    var onSilenceDetected: (() -> Void)?

    private var silenceStartTime: Date?
    private var hasFired = false
    private var hasHeardSpeech = false
    private var peakLevel: Float = 0.0

    // Simple approach: track the peak level seen, consider silence
    // as anything below 30% of the peak. No calibration delay.
    private let silenceRatio: Float = 0.3
    private let minimumPeakToArm: Float = 0.08  // Must see at least this level to consider "speech heard"
    private let absoluteSilenceFloor: Float = 0.04  // Below this is always silence

    func update(with level: Float) {
        // Track peak level
        if level > peakLevel {
            peakLevel = level
        }

        // Arm speech detection once we see a reasonable signal
        if level >= minimumPeakToArm {
            hasHeardSpeech = true
        }

        // Dynamic silence threshold: 30% of peak, but at least the absolute floor
        let silenceThreshold = max(absoluteSilenceFloor, peakLevel * silenceRatio)

        if level < silenceThreshold && hasHeardSpeech {
            if silenceStartTime == nil {
                silenceStartTime = Date()
            }

            silenceDuration = Date().timeIntervalSince(silenceStartTime!)
            isSilent = true

            if silenceDuration >= timeoutSeconds && !hasFired {
                hasFired = true
                print("[Wave] Silence detected after \(String(format: "%.1f", silenceDuration))s (peak: \(String(format: "%.3f", peakLevel)), threshold: \(String(format: "%.3f", silenceThreshold))) — auto-stopping")
                onSilenceDetected?()
            }
        } else {
            silenceStartTime = nil
            silenceDuration = 0
            isSilent = false
            hasFired = false
        }
    }

    func reset() {
        silenceStartTime = nil
        silenceDuration = 0
        isSilent = false
        hasFired = false
        hasHeardSpeech = false
        peakLevel = 0
    }
}
