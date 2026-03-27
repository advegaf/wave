import AppKit
import CoreGraphics

final class MediaPlaybackController {
    private var didPause = false

    func handleRecordingStart(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause:
            // Just send the pause key — no state check needed.
            // If nothing is playing, the key does nothing.
            print("[Wave] Sending media pause key")
            sendMediaKey(keyType: 16)
            didPause = true
        case .stop:
            sendMediaKey(keyType: 17)
            didPause = false
        case .doNothing:
            didPause = false
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause:
            if didPause {
                print("[Wave] Sending media resume key")
                sendMediaKey(keyType: 16)
                didPause = false
            }
        case .stop, .doNothing:
            break
        }
    }

    private func sendMediaKey(keyType: Int) {
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | (0xa << 8)),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cgSessionEventTap)

        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | (0xb << 8)),
            data2: -1
        )
        keyUp?.cgEvent?.post(tap: .cgSessionEventTap)
    }
}
