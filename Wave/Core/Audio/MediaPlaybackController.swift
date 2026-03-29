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

// MARK: - Helper Binary (checks isPlaying from a subprocess)

private enum MediaStateHelper {
    static let helperSource = """
    import Foundation
    let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
    guard let url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, path as CFString, .cfurlposixPathStyle, true),
          let bundle = CFBundleCreate(kCFAllocatorDefault, url) else { exit(1) }
    typealias RegFn = @convention(c) (DispatchQueue) -> Void
    if let p = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) {
        unsafeBitCast(p, to: RegFn.self)(DispatchQueue.main)
    }
    typealias IsPlayingFn = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    guard let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else { exit(1) }
    let check = unsafeBitCast(ptr, to: IsPlayingFn.self)
    check(DispatchQueue.main) { playing in
        exit(playing ? 0 : 1)
    }
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 2))
    exit(1)
    """

    static let supportDir: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Wave")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let binaryPath = supportDir.appendingPathComponent("media-state")
    static let sourcePath = supportDir.appendingPathComponent("media-state.swift")

    static func ensureCompiled() {
        if FileManager.default.fileExists(atPath: binaryPath.path) { return }

        try? helperSource.write(to: sourcePath, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        process.arguments = [sourcePath.path, "-o", binaryPath.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    static func isPlaying() -> Bool {
        ensureCompiled()
        guard FileManager.default.fileExists(atPath: binaryPath.path) else { return true }

        let process = Process()
        process.executableURL = binaryPath
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
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
            if MediaStateHelper.isPlaying() {
                send(command: 1) // kMRPause
                didPause = true
            } else {
                didPause = false
            }
        case .stop:
            send(command: 1)
            didPause = false
        case .doNothing:
            didPause = false
        }
    }

    func handleRecordingEnd(behavior: PlaybackBehavior) {
        guard case .pause = behavior, didPause else { return }
        send(command: 0) // kMRPlay
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
