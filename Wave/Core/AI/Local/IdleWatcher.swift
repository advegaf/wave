import Foundation

/// Generic background timer that fires `onIdleExceeded` when no `touch()` call
/// has been received within the configured `timeout`.
///
/// Used by `LocalAIEngine` to unload the MLX LLM (and optionally WhisperKit)
/// after a period of inactivity, so a menu-bar app doesn't hold ~2 GB of RAM
/// hostage when the user isn't dictating.
///
/// Lifecycle:
/// - Configure via `setTimeout(_:)`. Pass `nil` to disable, `0` to fire on
///   the next tick after every touch (effectively "unload immediately"),
///   or seconds for delayed unload.
/// - Call `start(onIdleExceeded:)` once. The watcher runs forever until
///   `stop()` is called.
/// - Call `touch()` after every action that should reset the idle clock.
actor IdleWatcher {

    /// Polling cadence — how often we check elapsed time. Matches Handy's 10 s tick.
    private let pollInterval: TimeInterval = 10

    private var timeout: TimeInterval?
    private var lastActivityAt: Date = .init()
    private var watcherTask: Task<Void, Never>?
    private var hasFiredSinceLastTouch: Bool = false

    /// Set the inactivity timeout in seconds. `nil` disables firing entirely.
    /// `0` means "fire on the very next tick after a touch" (immediate unload).
    func setTimeout(_ seconds: TimeInterval?) {
        timeout = seconds
        hasFiredSinceLastTouch = false
    }

    /// Start the polling task. The closure is invoked on the actor's executor.
    /// Calling `start` multiple times replaces the previous handler.
    func start(onIdleExceeded: @Sendable @escaping () async -> Void) {
        watcherTask?.cancel()
        watcherTask = Task { [weak self, pollInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pollInterval))
                guard let self else { return }
                let shouldFire = await self.tickAndCheck()
                if shouldFire {
                    await onIdleExceeded()
                }
            }
        }
    }

    /// Reset the idle clock. Call after every transcribe / rewrite.
    func touch() {
        lastActivityAt = .init()
        hasFiredSinceLastTouch = false
    }

    /// Stop watching. Idempotent.
    func stop() {
        watcherTask?.cancel()
        watcherTask = nil
    }

    /// Internal tick: returns true if `onIdleExceeded` should fire this round.
    /// We only fire once per inactivity window so consumers don't get spammed.
    private func tickAndCheck() -> Bool {
        guard let timeout else { return false }
        if hasFiredSinceLastTouch { return false }

        let elapsed = Date().timeIntervalSince(lastActivityAt)
        if elapsed >= timeout {
            hasFiredSinceLastTouch = true
            return true
        }
        return false
    }
}
