@preconcurrency import AVFoundation
import AppKit

/// Generates Siri-style two-tone chime sounds programmatically.
final class ChimeSynthesizer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    var volume: Float = 0.7

    /// Play a rising two-tone chime (recording start)
    func playStartChime() {
        playChime(frequencies: [880, 1175], duration: 0.08)
    }

    /// Play a falling two-tone chime (recording stop)
    func playStopChime() {
        playChime(frequencies: [1175, 880], duration: 0.08)
    }

    private func playChime(frequencies: [Double], duration: Double) {
        let sampleRate: Double = 44100
        let totalSamples = Int(sampleRate * duration * Double(frequencies.count))
        let samplesPerTone = Int(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)) else { return }

        buffer.frameLength = AVAudioFrameCount(totalSamples)
        guard let data = buffer.floatChannelData?[0] else { return }

        for (toneIndex, freq) in frequencies.enumerated() {
            let offset = toneIndex * samplesPerTone
            for i in 0..<samplesPerTone {
                let t = Double(i) / sampleRate
                // Sine wave with fast exponential decay envelope
                let envelope = exp(-t * 20.0) * Double(volume)
                let sample = Float(sin(2.0 * .pi * freq * t) * envelope)
                data[offset + i] = sample
            }
        }

        // Play using AVAudioEngine
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer) { [engine] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    engine.stop()
                }
            }
        } catch {
            print("[Wave] Chime playback failed: \(error)")
        }
    }
}
