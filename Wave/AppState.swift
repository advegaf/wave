import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Settings (loaded from UserPreferences)
    var selectedRewriteLevel: RewriteLevel
    var selectedLocalLLMModelId: String
    var llmIdleTimeoutSeconds: TimeInterval?
    var overlayStyle: OverlayStyle
    var silenceTimeoutSeconds: Double
    var soundEffectsEnabled: Bool
    var soundEffectsVolume: Float
    var autoIncreaseVolume: Bool
    var silenceRemoval: Bool
    var playbackBehavior: PlaybackBehavior
    var hasCompletedSetup: Bool
    var overlayPositionY: CGFloat

    init() {
        let prefs = UserPreferences()
        self.selectedRewriteLevel = RewriteLevel(rawValue: prefs.rewriteLevel) ?? .raw
        let storedId = prefs.selectedLocalLLMModelId
        self.selectedLocalLLMModelId = storedId.isEmpty ? LocalLLMRegistry.defaultModelId : storedId
        switch prefs.llmIdleTimeoutSecondsRaw {
        case ..<0:
            self.llmIdleTimeoutSeconds = nil
        case let value:
            self.llmIdleTimeoutSeconds = TimeInterval(value)
        }
        self.overlayStyle = OverlayStyle(rawValue: prefs.overlayStyle) ?? .full
        self.silenceTimeoutSeconds = prefs.silenceTimeout
        self.soundEffectsEnabled = prefs.soundEffectsEnabled
        self.soundEffectsVolume = Float(prefs.soundEffectsVolume)
        self.autoIncreaseVolume = prefs.autoIncreaseVolume
        self.silenceRemoval = prefs.silenceRemoval
        self.hasCompletedSetup = prefs.hasCompletedSetup
        self.overlayPositionY = CGFloat(prefs.overlayPositionY)

        // Migrate from old autoPauseMedia bool to PlaybackBehavior
        if let oldValue = UserDefaults.standard.object(forKey: "autoPauseMedia") as? Bool {
            self.playbackBehavior = oldValue ? .pause : .doNothing
            UserDefaults.standard.removeObject(forKey: "autoPauseMedia")
            prefs.playbackBehavior = self.playbackBehavior.rawValue
        } else {
            self.playbackBehavior = PlaybackBehavior(rawValue: prefs.playbackBehavior) ?? .doNothing
        }

        // Migrate existing users: reset to .doNothing since .pause previously
        // launched Apple Music when no media was playing
        if UserDefaults.standard.object(forKey: "playbackBehaviorMigratedV2") == nil {
            self.playbackBehavior = .doNothing
            prefs.playbackBehavior = PlaybackBehavior.doNothing.rawValue
            UserDefaults.standard.set(true, forKey: "playbackBehaviorMigratedV2")
        }
    }

    /// Save all current settings to UserPreferences (auto-save)
    func saveToPreferences() {
        let prefs = UserPreferences()
        prefs.rewriteLevel = selectedRewriteLevel.rawValue
        prefs.selectedLocalLLMModelId = selectedLocalLLMModelId
        prefs.llmIdleTimeoutSecondsRaw = llmIdleTimeoutSeconds.map { Int($0) } ?? -1
        prefs.overlayStyle = overlayStyle.rawValue
        prefs.silenceTimeout = silenceTimeoutSeconds
        prefs.soundEffectsEnabled = soundEffectsEnabled
        prefs.soundEffectsVolume = Double(soundEffectsVolume)
        prefs.autoIncreaseVolume = autoIncreaseVolume
        prefs.silenceRemoval = silenceRemoval
        prefs.playbackBehavior = playbackBehavior.rawValue
        prefs.hasCompletedSetup = hasCompletedSetup
        prefs.overlayPositionY = Double(overlayPositionY)
    }

    // MARK: - WhisperKit Status
    var whisperKitError: String?
    var isWhisperKitReady: Bool = false

    // MARK: - Navigation
    var selectedSidebarItem: SidebarItem = .home
    var isMainWindowOpen: Bool = false

}

// MARK: - Enums

enum RewriteLevel: String, CaseIterable, Codable {
    case raw = "Raw"
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"

    /// True for any mode that requires a local LLM. Raw is the only false case.
    /// Use this everywhere we'd otherwise have to compare against `.raw` directly.
    var requiresLLM: Bool { self != .raw }

    var description: String {
        switch self {
        case .raw: "Just transcribe and paste. No cleanup. Most predictable, fastest, no LLM required."
        case .light: "Remove fillers and false starts. Pure cleanup, near-zero hallucination risk."
        case .moderate: "Fix grammar and split run-on sentences. Preserves your voice."
        case .heavy: "Adapt tone for the active app. Casual in Slack, formal in Mail."
        }
    }

    var promptFileName: String {
        switch self {
        case .raw: ""  // never read; callers gate on requiresLLM first
        case .light: "light_rewrite"
        case .moderate: "moderate_rewrite"
        case .heavy: "heavy_rewrite"
        }
    }

    var next: RewriteLevel {
        switch self {
        case .raw: .light
        case .light: .moderate
        case .moderate: .heavy
        case .heavy: .raw
        }
    }
}

enum PlaybackBehavior: String, CaseIterable, Codable {
    case pause = "Pause"
    case stop = "Stop"
    case doNothing = "Do nothing"
}

// Provider type enums collapsed to single cases. The fully-local backend
// has exactly one transcription engine (WhisperKit) and one rewrite engine
// (the active local LLM via MLX). They remain as types so existing UI bindings
// don't have to be rewritten in step 11.

enum TranscriptionProviderType: String, CaseIterable, Codable, Identifiable {
    case whisperKit = "WhisperKit"

    var id: String { rawValue }

    var iconName: String { "waveform.circle" }
}

enum RewriteProviderType: String, CaseIterable, Codable, Identifiable {
    case localLLM = "Local LLM"

    var id: String { rawValue }

    var iconName: String { "cpu" }
}

enum OverlayStyle: String, CaseIterable, Codable {
    case full = "Full"
    case mini = "Mini"

    var description: String {
        switch self {
        case .full: "Full-size Siri waveform"
        case .mini: "Compact waveform"
        }
    }

    var width: CGFloat {
        switch self {
        case .full: 500
        case .mini: 300
        }
    }

    var height: CGFloat {
        switch self {
        case .full: 120
        case .mini: 100
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case modes = "Modes"
    case vocabulary = "Vocabulary"
    case snippets = "Snippets"
    case configuration = "Configuration"
    case sound = "Sound"
    case modelsLibrary = "Models Library"
    case history = "History"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .modes: "slider.horizontal.3"
        case .vocabulary: "book.fill"
        case .snippets: "doc.text.fill"
        case .configuration: "gearshape"
        case .sound: "speaker.wave.2.fill"
        case .modelsLibrary: "cpu"
        case .history: "clock.arrow.circlepath"
        }
    }

    var iconColor: Color {
        switch self {
        case .home: .blue
        case .modes: .purple
        case .vocabulary: .green
        case .snippets: .orange
        case .configuration: .gray
        case .sound: .gray
        case .modelsLibrary: .teal
        case .history: .indigo
        }
    }
}
