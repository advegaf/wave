import AppKit
import AVFoundation
import Observation

@MainActor
@Observable
final class RecordingCoordinator: @unchecked Sendable {
    // MARK: - State
    private(set) var state: RecordingState = .idle
    private(set) var lastCleanedText: String?
    private(set) var lastError: String?

    // MARK: - Dependencies
    let audioEngine = AudioCaptureEngine()
    let levelMonitor = AudioLevelMonitor()
    let timeLimiter = RecordingTimeLimiter()
    nonisolated(unsafe) let clipboardManager = ClipboardManager()
    nonisolated(unsafe) let activeAppDetector = ActiveAppDetector()
    nonisolated(unsafe) let mediaController = MediaPlaybackController()
    nonisolated let localAI = LocalAIEngine()

    // MARK: - Settings (injected from AppState)
    var rewriteLevel: RewriteLevel = .raw {
        didSet {
            guard rewriteLevel != oldValue else { return }
            // Lazy LLM load: switching INTO any non-Raw mode triggers a download
            // (if needed) and parks the model in memory. Switching back to Raw
            // does nothing here — the idle watcher will eventually unload.
            if rewriteLevel.requiresLLM {
                Task { [localAI, selectedLocalLLMModelId] in
                    try? await localAI.setActiveLLM(id: selectedLocalLLMModelId)
                }
            }
        }
    }
    var soundEffectsEnabled: Bool = true
    var soundEffectsVolume: Float = 0.7 { didSet { chime.volume = soundEffectsVolume } }
    var playbackBehavior: PlaybackBehavior = .pause
    var selectedLocalLLMModelId: String = LocalLLMRegistry.defaultModelId {
        didSet {
            guard selectedLocalLLMModelId != oldValue else { return }
            Task { try? await localAI.setActiveLLM(id: selectedLocalLLMModelId) }
        }
    }
    var llmIdleTimeoutSeconds: TimeInterval? = 300 {
        didSet { Task { await localAI.setIdleTimeout(llmIdleTimeoutSeconds) } }
    }

    // MARK: - Overlay & Hotkey
    var overlayController: OverlayWindowController?
    var hotkeyManager: GlobalHotkeyManager?
    var overlayStyle: OverlayStyle = .full
    var overlayPositionY: CGFloat = 10

    // MARK: - Pre-fetched Context (loaded during recording)
    private var prefetchedDictionary: [DictionaryEntry] = []
    private var prefetchedSnippets: [Snippet] = []
    private var prefetchedContext: RewriteContext?
    private var prefetchTask: Task<Void, Never>?

    // MARK: - Sound
    private let chime = ChimeSynthesizer()

    init() {
        setupAudioCallbacks()
        setupSpeechEndDetection()
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
        levelMonitor.reset()
        overlayController?.hide()
        mediaController.handleRecordingEnd(behavior: playbackBehavior)
        clearPrefetchedData()
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

        // Handle media playback
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
        lastError = nil

        state = .recording

        // Pre-fetch rewrite context while user is still talking
        prefetchTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            self.prefetchedDictionary = (try? DatabaseManager.shared.fetchDictionaryEntries()) ?? []
            self.prefetchedSnippets = (try? DatabaseManager.shared.fetchSnippets()) ?? []
            guard !Task.isCancelled else { return }
            self.prefetchedContext = RewriteContext(
                activeAppName: self.activeAppDetector.capturedAppName,
                rewriteLevel: self.rewriteLevel,
                customDictionary: self.prefetchedDictionary,
                suggestedTone: self.activeAppDetector.suggestedTone
            )
        }
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
        levelMonitor.reset()

        // Resume media immediately when recording stops
        mediaController.handleRecordingEnd(behavior: playbackBehavior)

        // Process in background
        Task {
            await processRecording()
        }
    }

    private func processRecording() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            // 1. Pull resampled 16 kHz mono Float samples from the capture engine
            //    (no WAV round-trip — VAD already saw real-time audio).
            let samples = audioEngine.getResampledSamples()
            audioEngine.clearBuffers()

            let convertTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Audio: \(samples.count) samples (\(Int((convertTime - startTime) * 1000))ms)")

            guard samples.count > 1600 else {  // <0.1s of audio at 16kHz — discard
                state = .idle
                return
            }

            // 2. Build rewrite context from prefetched data or fall back to a fresh fetch.
            let context = prefetchedContext ?? RewriteContext(
                activeAppName: activeAppDetector.capturedAppName,
                rewriteLevel: rewriteLevel,
                customDictionary: (try? DatabaseManager.shared.fetchDictionaryEntries()) ?? [],
                suggestedTone: activeAppDetector.suggestedTone
            )

            // 3. Transcribe via LocalAIEngine → WhisperKit
            let rawTranscript = try await localAI.transcribe(samples: samples)

            let transcribeTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Transcribed: \"\(rawTranscript)\" (\(Int((transcribeTime - convertTime) * 1000))ms)")

            // Filter out Whisper artifacts — any text that is entirely [tags] or (tags)
            let cleaned = rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
            let isArtifact = cleaned.range(
                of: #"^(\[[\w\s\-']+\]|\([\w\s\-']+\)|\s|\.)+$"#,
                options: .regularExpression
            ) != nil

            guard !cleaned.isEmpty, !isArtifact else {
                print("[Wave] Skipping — empty or Whisper artifact: \"\(cleaned)\"")
                state = .idle
                return
            }

            // 4. Snippet detection (use pre-fetched snippets)
            let snippets = prefetchedSnippets.isEmpty ? ((try? DatabaseManager.shared.fetchSnippets()) ?? []) : prefetchedSnippets
            let snippetResult = detectSnippet(in: cleaned, snippets: snippets)

            let cleanedText: String
            let rewriteTime: CFAbsoluteTime

            switch snippetResult {
            case .exactMatch(let content):
                // Entire transcript is a trigger phrase — paste snippet directly, skip LLM
                cleanedText = content
                rewriteTime = CFAbsoluteTimeGetCurrent()
                print("[Wave] Snippet exact match — skipping LLM (\(Int((rewriteTime - transcribeTime) * 1000))ms)")

            case .partialMatch(let expandedText):
                if rewriteLevel.requiresLLM {
                    // Trigger phrase found within sentence — replace and send to LLM
                    print("[Wave] Snippet partial match — sending expanded text to LLM")
                    cleanedText = try await localAI.rewrite(text: expandedText, context: context)
                    rewriteTime = CFAbsoluteTimeGetCurrent()
                    print("[Wave] Rewritten: \"\(cleanedText)\" (\(Int((rewriteTime - transcribeTime) * 1000))ms)")
                } else {
                    // Raw mode — paste expanded snippet text without LLM cleanup
                    cleanedText = expandedText
                    rewriteTime = CFAbsoluteTimeGetCurrent()
                    print("[Wave] Snippet partial match — Raw mode, no LLM (\(Int((rewriteTime - transcribeTime) * 1000))ms)")
                }

            case .noMatch:
                if rewriteLevel.requiresLLM {
                    // No snippets — normal LLM rewrite
                    cleanedText = try await localAI.rewrite(text: rawTranscript, context: context)
                    rewriteTime = CFAbsoluteTimeGetCurrent()
                    print("[Wave] Rewritten: \"\(cleanedText)\" (\(Int((rewriteTime - transcribeTime) * 1000))ms)")
                } else {
                    // Raw mode — paste the transcript verbatim
                    cleanedText = rawTranscript
                    rewriteTime = CFAbsoluteTimeGetCurrent()
                    print("[Wave] Raw mode — pasting transcript directly (\(Int((rewriteTime - transcribeTime) * 1000))ms)")
                }
            }

            // 5. Paste immediately (app should already have focus from step 2)
            state = .pasting
            lastCleanedText = cleanedText
            await clipboardManager.pasteText(cleanedText)

            let pasteTime = CFAbsoluteTimeGetCurrent()
            print("[Wave] Total pipeline: \(Int((pasteTime - startTime) * 1000))ms")

            // 6. Save history in background (don't block the paste)
            let languageModelLabel: String
            if rewriteLevel.requiresLLM {
                languageModelLabel = LocalLLMRegistry.find(id: selectedLocalLLMModelId)?.displayName ?? selectedLocalLLMModelId
            } else {
                languageModelLabel = "(none — Raw)"
            }
            let entry = HistoryEntry(
                rawTranscript: rawTranscript,
                cleanedText: cleanedText,
                rewriteLevel: rewriteLevel.rawValue,
                sourceApp: activeAppDetector.capturedAppName,
                voiceModel: "WhisperKit",
                languageModel: languageModelLabel,
                durationSeconds: timeLimiter.elapsedSeconds,
                wordCount: cleanedText.split(separator: " ").count
            )
            Task.detached { try? DatabaseManager.shared.addHistoryEntry(entry) }

            activeAppDetector.reset()
            clearPrefetchedData()
            state = .idle

        } catch {
            print("[Wave] ERROR: \(error)")
            lastError = error.localizedDescription
            clearPrefetchedData()
            state = .idle
        }
    }

    // MARK: - Setup

    private func setupAudioCallbacks() {
        audioEngine.onAudioLevel = { [weak self] level in
            self?.levelMonitor.update(with: level)
        }
    }

    private func setupSpeechEndDetection() {
        audioEngine.onSpeechEnded = { [weak self] in
            // Already on main; AudioCaptureEngine.handleVAD is @MainActor.
            self?.stopRecording()
        }
    }

    /// Preload WhisperKit + (optionally) the active local LLM, plus the Silero
    /// VAD model. Run during app startup. The LLM is only preloaded when the
    /// saved mode actually needs it — Raw users never trigger a download.
    func preloadWhisperModel(appState: AppState? = nil) {
        Task { [audioEngine, localAI] in
            await audioEngine.prepareVAD()
            await localAI.startIdleWatcher()
            await localAI.setIdleTimeout(self.llmIdleTimeoutSeconds)
            // Skip LLM preload entirely in Raw mode — the user may never want
            // a 2 GB download.
            let llmIdToPreload: String? = self.rewriteLevel.requiresLLM ? self.selectedLocalLLMModelId : nil
            await localAI.preloadActiveModels(activeLLMId: llmIdToPreload)
            let ready = await localAI.whisperReady
            await MainActor.run {
                appState?.isWhisperKitReady = ready
                appState?.whisperKitError = ready ? nil : "WhisperKit failed to load"
            }
        }
    }

    func clearWhisperKitCache() {
        Task { await localAI.clearWhisperKitCache() }
    }

    private func clearPrefetchedData() {
        prefetchTask?.cancel()
        prefetchTask = nil
        prefetchedDictionary = []
        prefetchedSnippets = []
        prefetchedContext = nil
    }

    private func playHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }

    // MARK: - Snippet Detection

    private enum SnippetResult {
        case exactMatch(String)    // Entire transcript is a trigger — use snippet content directly
        case partialMatch(String)  // Trigger found in sentence — expanded text with snippet content
        case noMatch
    }

    private func detectSnippet(in transcript: String, snippets: [Snippet]) -> SnippetResult {
        guard !snippets.isEmpty else { return .noMatch }

        let lowered = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for exact match first (entire transcript is just the trigger phrase)
        for snippet in snippets {
            let trigger = snippet.triggerPhrase.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if lowered == trigger {
                print("[Wave] Snippet exact match: \"\(snippet.triggerPhrase)\" → expanding")
                return .exactMatch(snippet.content)
            }
        }

        // Check for partial match (trigger phrase appears as a word within the sentence)
        var expandedText = transcript
        var didReplace = false

        for snippet in snippets {
            let trigger = snippet.triggerPhrase
            // Case-insensitive word boundary match
            if let range = expandedText.range(of: trigger, options: [.caseInsensitive]) {
                expandedText = expandedText.replacingCharacters(in: range, with: snippet.content)
                didReplace = true
                print("[Wave] Snippet partial match: \"\(trigger)\" replaced in sentence")
            }
        }

        if didReplace {
            return .partialMatch(expandedText)
        }

        return .noMatch
    }
}
