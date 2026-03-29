import Foundation

// MARK: - MediaRemote Bridge (private framework, loaded dynamically)

private enum MediaRemoteBridge {
    typealias SendCommandFn = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool
    typealias RegisterFn = @convention(c) (DispatchQueue) -> Void

    nonisolated(unsafe) private static let bundle: CFBundle? = {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
        guard let url = CFURLCreateWithFileSystemPath(
            kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, true
        ) else { return nil }
        return CFBundleCreate(kCFAllocatorDefault, url)
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
    private var didRegister = false

    func handleRecordingStart(behavior: PlaybackBehavior) {
        ensureRegistered()

        switch behavior {
        case .pause:
            send(command: 1) // kMRPause — idempotent, no effect if already paused
            didPause = true
        case .stop:
            send(command: 1)
            didPause = false
        case .doNothing:
            didPause = false
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        guard case .pause = behavior, didPause else { return }
        send(command: 0) // kMRPlay — idempotent, no effect if already playing
        didPause = false
    }

    private func ensureRegistered() {
        guard !didRegister else { return }
        didRegister = true
        MediaRemoteBridge.register()
    }

    private func send(command: UInt32) {
        guard let sendFn = MediaRemoteBridge.sendCommand else { return }
        let _ = sendFn(command, nil)
    }
}
