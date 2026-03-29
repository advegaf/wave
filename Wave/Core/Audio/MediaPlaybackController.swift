import AppKit
import CoreGraphics

// MARK: - MediaRemote Bridge (private framework, loaded dynamically)

private enum MediaRemoteBridge {
    typealias IsPlayingCallback = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    typealias SendCommandFn = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool
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

// MARK: - File Logger

private func mediaLog(_ message: String) {
    let logDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/Wave")
    try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
    let logFile = logDir.appendingPathComponent("media.log")
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "[\(ts)] \(message)\n"
    if let data = line.data(using: .utf8) {
        if let handle = try? FileHandle(forWritingTo: logFile) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: logFile)
        }
    }
}

// MARK: - Media Playback Controller

final class MediaPlaybackController {
    private var didPause = false
    private var didRegister = false

    func handleRecordingStart(behavior: PlaybackBehavior) async {
        mediaLog("handleRecordingStart called, behavior=\(behavior)")

        switch behavior {
        case .pause:
            let playing = await isMediaCurrentlyPlaying()
            mediaLog("isPlaying=\(playing)")
            if playing {
                mediaLog("Sending togglePlayPause")
                sendCommand(.togglePlayPause)
                didPause = true
            } else {
                mediaLog("No media playing, skipping")
                didPause = false
            }
        case .stop:
            let playing = await isMediaCurrentlyPlaying()
            if playing {
                sendCommand(.togglePlayPause)
            }
            didPause = false
        case .doNothing:
            mediaLog("Behavior is doNothing, skipping")
            didPause = false
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        switch behavior {
        case .pause:
            if didPause {
                mediaLog("Resuming media — sending togglePlayPause")
                sendCommand(.togglePlayPause)
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

    private func ensureRegistered() {
        guard !didRegister else { return }
        didRegister = true

        mediaLog("Registering with MediaRemote...")
        mediaLog("  bundle loaded: \(MediaRemoteBridge.isPlaying != nil || MediaRemoteBridge.sendCommand != nil)")
        mediaLog("  isPlaying fn: \(MediaRemoteBridge.isPlaying != nil)")
        mediaLog("  sendCommand fn: \(MediaRemoteBridge.sendCommand != nil)")
        mediaLog("  register fn: \(MediaRemoteBridge.registerForNotifications != nil)")

        MediaRemoteBridge.register()
        mediaLog("Registration done")
    }

    private func isMediaCurrentlyPlaying() async -> Bool {
        ensureRegistered()

        guard let isPlayingFn = MediaRemoteBridge.isPlaying else {
            mediaLog("isPlaying function is nil — MediaRemote unavailable")
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
            mediaLog("sendCommand function is nil — cannot send")
            return
        }
        let result = sendFn(command.rawValue, nil)
        mediaLog("sendCommand(\(command), rawValue=\(command.rawValue)) returned \(result)")
    }
}
