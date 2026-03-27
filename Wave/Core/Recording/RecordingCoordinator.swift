import AppKit
import AVFoundation
import Observation

@Observable
final class RecordingCoordinator: @unchecked Sendable {
    // MARK: - State
    private(set) var state: RecordingState = .idle
    private(set) var lastCleanedText: String?
    private(set) var lastError: String?

    // MARK: - Dependencies
    let audioEngine = AudioCaptureEngine()
    let levelMonitor = AudioLevelMonitor()
    let silenceDetector = SilenceDetector()
    let timeLimiter = RecordingTimeLimiter()
    let clipboardManager = ClipboardManager()
    let activeAppDetector = ActiveAppDetector()
    let mediaController = MediaPlaybackController()
    let transcriptionService = TranscriptionService()
    let rewriteService = RewriteService()

    // MARK: - Settings (injected from AppState)
    var rewriteLevel: RewriteLevel = .moderate
    var transcriptionProvider: TranscriptionProviderType = .whisper
    var rewriteProvider: RewriteProviderType = .claude
    var soundEffectsEnabled: Bool = true
    var playbackBehavior: PlaybackBehavior = .pause

    // MARK: - Overlay & Hotkey
    var overlayController: OverlayWindowController?
    var hotkeyManager: GlobalHotkeyManager?
    var overlayStyle: OverlayStyle = .full
    var overlayPositionY: CGFloat = 10

    // MARK: - Sound
    private let chime = ChimeSynthesizer()

    init() {
        setupAudioCallbacks()
        setupSilenceDetection()
        setupAIProviders()
    }

    // MARK: - Public Actions

    func toggleRecording() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        default:
            break // Ignore during processing/pasting
        }
    }

    func cancelRecording() {
        guard state == .recording || state == .activating else { return }
        state = .cancelling
        hotkeyManager?.stopListeningForEscape()
        audioEngine.stop()
        audioEngine.clearBuffers()
        timeLimiter.stop()
        silenceDetector.reset()
        levelMonitor.reset()
        overlayController?.hide()
        state = .idle
    }

    func startPushToTalk() {
        guard state == .idle else { return }
        startRecording()
    }

    func stopPushToTalk() {
        guard state == .recording else { return }
        stopRecording()
    }

    // MARK: - Private

    private func startRecording() {
        state = .activating

        // Capture active app before Wave takes focus
        activeAppDetector.captureActiveApp()

        // Play start chime
        if soundEffectsEnabled {
            playHaptic()
            chime.playStartChime()
        }

        // Handle media playback based on behavior setting
        mediaController.handleRecordingStart(behavior: playbackBehavior)

        // Show overlay waveform (sync style + position before showing)
        overlayController?.overlayStyle = overlayStyle
        overlayController?.positionY = overlayPositionY
        overlayController?.show(levelMonitor: levelMonitor)

        // Start listening for escape
        hotkeyManager?.startListeningForEscape()

        // Start audio capture
        audioEngine.start()
        timeLimiter.start()
        silenceDetector.reset()
        lastError = nil

        state = .recording
    }

    private func stopRecording() {
        guard state == .recording else { return }

        state = .processing

        // Play stop chime
        if soundEffectsEnabled {
            playHaptic()
            chime.playStopChime()
        }

        // Hide overlay + stop escape
        overlayController?.hide()
        hotkeyManager?.stopListeningForEscape()

        // Stop capture
        audioEngine.stop()
        timeLimiter.stop()
        silenceDetector.reset()
        levelMonitor.reset()

        // Process in background
        Task {
            await processRecording()
        }
    }

    private func processRecording() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // 1. Convert audio to WAV (fast, in-memory)
            let audioData = audioEngine.getAccumulatedWAVData()
            audioEngine.clearBuffers()

            let convertTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Audio: \(audioData.count) bytes (\(Int((convertTime - startTime) * 1000))ms)")

            guard audioData.count > 44 else {
                state = .idle
                return
            }

            // 2. Don't re-activate any app — paste into whatever app
            //    has focus when processing finishes (user may have switched)

            // 3. Transcribe — build context in parallel while waiting
            let dictionary = (try? DatabaseManager.shared.fetchDictionaryEntries()) ?? []
            let context = RewriteContext(
                activeAppName: activeAppDetector.capturedAppName,
                rewriteLevel: rewriteLevel,
                customDictionary: dictionary,
                suggestedTone: activeAppDetector.suggestedTone
            )

            let rawTranscript = try await transcriptionService.transcribe(
                audioData: audioData,
                using: transcriptionProvider
            )

            let transcribeTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Transcribed: \"\(rawTranscript)\" (\(Int((transcribeTime - convertTime) * 1000))ms)")

            // Filter out Whisper artifacts (non-speech descriptions)
            let cleaned = rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            let whisperArtifacts = ["(stuttering)", "[sad music]", "(silence)", "[music]",
                                     "[applause]", "(inaudible)", "[laughter]", "[noise]",
                                     "(no audio)", "[blank_audio]", "(no speech)"]
            let isArtifact = whisperArtifacts.contains(where: { cleaned.localizedCaseInsensitiveContains($0) })
                             && cleaned.count < 30

            guard !cleaned.isEmpty, !isArtifact else {
                print("[Wave] Skipping — empty or Whisper artifact: \"\(cleaned)\"")
                state = .idle
                return
            }

            // 4. Rewrite with LLM
            let cleanedText = try await rewriteService.rewrite(
                text: rawTranscript,
                context: context,
                using: rewriteProvider
            )

            let rewriteTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Rewritten: \"\(cleanedText)\" (\(Int((rewriteTime - transcribeTime) * 1000))ms)")

            // 5. Paste immediately (app should already have focus from step 2)
            state = .pasting
            lastCleanedText = cleanedText
            await clipboardManager.pasteText(cleanedText)

            let pasteTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Total pipeline: \(Int((pasteTime - startTime) * 1000))ms")

            // 6. Save history in background (don't block the paste)
            let entry = HistoryEntry(
                rawTranscript: rawTranscript,
                cleanedText: cleanedText,
                rewriteLevel: rewriteLevel.rawValue,
                sourceApp: activeAppDetector.capturedAppName,
                voiceModel: transcriptionProvider.rawValue,
                languageModel: rewriteProvider.rawValue,
                durationSeconds: timeLimiter.elapsedSeconds,
                wordCount: cleanedText.split(separator: " ").count
            )
            Task.detached { try? DatabaseManager.shared.addHistoryEntry(entry) }

            mediaController.handleRecordingEnd(behavior: playbackBehavior)
            activeAppDetector.reset()
            state = .idle

        } catch {
            print("[Wave] ERROR: \(error)")
            lastError = error.localizedDescription
            state = .idle
            mediaController.handleRecordingEnd(behavior: playbackBehavior)
        }
    }

    // MARK: - Setup

    private func setupAudioCallbacks() {
        audioEngine.onAudioLevel = { [weak self] level in
            self?.levelMonitor.update(with: level)
            self?.silenceDetector.update(with: level)
        }
    }

    private func setupSilenceDetection() {
        silenceDetector.onSilenceDetected = { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.stopRecording()
            }
        }
    }

    private let whisperKitProvider = WhisperKitProvider()

    private func setupAIProviders() {
        transcriptionService.registerProvider(DeepgramProvider())
        transcriptionService.registerProvider(whisperKitProvider)
        rewriteService.registerProvider(ClaudeProvider())
        rewriteService.registerProvider(GPTProvider())
    }

    /// Pre-initialize WhisperKit model so first transcription is fast
    func preloadWhisperModel() {
        Task {
            try? await whisperKitProvider.initialize()
        }
    }

    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}
