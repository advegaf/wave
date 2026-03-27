import AppKit
import CoreGraphics

final class MediaPlaybackController {
    private var wasPlaying = false

    // MARK: - Public

    func pauseMediaIfPlaying() {
        // Check if media is actually playing before toggling
        checkNowPlayingState { [weak self] isPlaying in
            guard let self, isPlaying else {
                print("[Wave] Media not playing — skipping pause")
                return
            }
            print("[Wave] Media is playing — pausing")
            self.wasPlaying = true
            self.sendMediaKey(keyType: 16) // NX_KEYTYPE_PLAY (toggle)
        }
    }

    func resumeMediaIfPaused() {
        guard wasPlaying else { return }
        print("[Wave] Resuming media playback")
        sendMediaKey(keyType: 16)
        wasPlaying = false
    }

    func stopMedia() {
        sendMediaKey(keyType: 17) // NX_KEYTYPE_STOP
        wasPlaying = false
    }

    func handleRecordingStart(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause: pauseMediaIfPlaying()
        case .stop: stopMedia()
        case .doNothing: break
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause: resumeMediaIfPaused()
        case .stop, .doNothing: break
        }
    }

    // MARK: - Now Playing State Detection via MediaRemote

    private func checkNowPlayingState(completion: @escaping (Bool) -> Void) {
        // Load MediaRemote private framework
        guard let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            URL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework") as CFURL
        ) else {
            completion(false)
            return
        }

        // Get MRMediaRemoteGetNowPlayingInfo function
        guard let pointer = CFBundleGetFunctionPointerForName(
            bundle,
            "MRMediaRemoteGetNowPlayingInfo" as CFString
        ) else {
            completion(false)
            return
        }

        typealias MRGetNowPlayingInfoFunc = @convention(c) (
            DispatchQueue,
            @escaping ([String: Any]) -> Void
        ) -> Void

        let getNowPlayingInfo = unsafeBitCast(pointer, to: MRGetNowPlayingInfoFunc.self)

        getNowPlayingInfo(DispatchQueue.main) { info in
            // PlaybackRate > 0 means media is actively playing
            let playbackRate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
            completion(playbackRate > 0)
        }
    }

    // MARK: - Media Key Simulation

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
