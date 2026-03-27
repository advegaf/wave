import AppKit
import CoreGraphics

// MARK: - MediaRemote Bridge (private framework, loaded dynamically)

private enum MediaRemoteBridge {
    typealias NowPlayingInfoCallback = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void

    static let getNowPlayingInfo: NowPlayingInfoCallback? = {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
        guard let url = CFURLCreateWithFileSystemPath(
            kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, true
        ) else { return nil }
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, url) else { return nil }
        guard let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return nil }
        return unsafeBitCast(ptr, to: NowPlayingInfoCallback.self)
    }()
}

final class MediaPlaybackController {
    private var didPause = false

    func handleRecordingStart(behavior: PlaybackBehavior) async {
        switch behavior {
        case .pause:
            let isPlaying = await isMediaCurrentlyPlaying()
            if isPlaying {
                print("[Wave] Media is playing — sending pause key")
                sendMediaKey(keyType: 16)
                didPause = true
            } else {
                print("[Wave] No media playing — skipping pause key")
                didPause = false
            }
        case .stop:
            let isPlaying = await isMediaCurrentlyPlaying()
            if isPlaying {
                sendMediaKey(keyType: 17)
            }
            didPause = false
        case .doNothing:
            didPause = false
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause:
            if didPause {
                print("[Wave] Resuming media playback")
                sendMediaKey(keyType: 16)
                didPause = false
            }
        case .stop, .doNothing:
            break
        }
    }

    private func isMediaCurrentlyPlaying() async -> Bool {
        guard let getNowPlayingInfo = MediaRemoteBridge.getNowPlayingInfo else {
            print("[Wave] MediaRemote unavailable — media pause disabled")
            return false
        }
        return await withCheckedContinuation { continuation in
            getNowPlayingInfo(DispatchQueue.main) { info in
                let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
                continuation.resume(returning: rate > 0)
            }
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
