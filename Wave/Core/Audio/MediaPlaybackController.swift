import AppKit
import CoreGraphics

// MARK: - MediaRemote Bridge (private framework, loaded dynamically)

private enum MediaRemoteBridge {
    // Detection: direct boolean "is anything playing?"
    typealias IsPlayingCallback = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void

    // Control: send command directly to Now Playing app via media daemon
    // Commands: 0=Play, 1=Pause, 2=TogglePlayPause, 3=Stop
    typealias SendCommandFn = @convention(c) (UInt32, CFDictionary?) -> Bool

    // Registration: required before queries return accurate state
    typealias RegisterFn = @convention(c) (DispatchQueue) -> Void

    nonisolated(unsafe) private static let bundle: CFBundle? = {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
        guard let url = CFURLCreateWithFileSystemPath(
            kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, true
        ) else { return nil }
        return CFBundleCreate(kCFAllocatorDefault, url)
    }()

    static let isPlaying: IsPlayingCallback? = {
        guard let bundle, let ptr = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString
        ) else { return nil }
        return unsafeBitCast(ptr, to: IsPlayingCallback.self)
    }()

    static let sendCommand: SendCommandFn? = {
        guard let bundle, let ptr = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteSendCommand" as CFString
        ) else { return nil }
        return unsafeBitCast(ptr, to: SendCommandFn.self)
    }()

    static let registerForNotifications: RegisterFn? = {
        guard let bundle, let ptr = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString
        ) else { return nil }
        return unsafeBitCast(ptr, to: RegisterFn.self)
    }()

    static func register() {
        registerForNotifications?(DispatchQueue.main)
    }
}

// MARK: - Media Playback Controller

final class MediaPlaybackController {
    private var didPause = false

    init() {
        // Register with MediaRemote so queries return accurate state
        MediaRemoteBridge.register()
    }

    func handleRecordingStart(behavior: PlaybackBehavior) async {
        switch behavior {
        case .pause:
            let playing = await isMediaCurrentlyPlaying()
            if playing {
                print("[Wave] Media is playing — sending pause via MediaRemote")
                sendCommand(.pause)
                didPause = true
            } else {
                print("[Wave] No media playing — skipping pause")
                didPause = false
            }
        case .stop:
            let playing = await isMediaCurrentlyPlaying()
            if playing {
                sendCommand(.stop)
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
                print("[Wave] Resuming media via MediaRemote")
                sendCommand(.play)
                didPause = false
            }
        case .stop, .doNothing:
            break
        }
    }

    // MARK: - Private

    private enum MediaCommand: UInt32 {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case stop = 3
    }

    private func isMediaCurrentlyPlaying() async -> Bool {
        guard let isPlayingFn = MediaRemoteBridge.isPlaying else {
            print("[Wave] MediaRemote unavailable — media pause disabled")
            return false
        }
        return await withCheckedContinuation { continuation in
            isPlayingFn(DispatchQueue.main) { isPlaying in
                continuation.resume(returning: isPlaying)
            }
        }
    }

    private func sendCommand(_ command: MediaCommand) {
        guard let sendFn = MediaRemoteBridge.sendCommand else {
            print("[Wave] MediaRemote sendCommand unavailable")
            return
        }
        let _ = sendFn(command.rawValue, nil)
    }
}
