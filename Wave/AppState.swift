import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - Settings (loaded from UserPreferences)
    var selectedRewriteLevel: RewriteLevel
    var selectedTranscriptionProvider: TranscriptionProviderType
    var selectedRewriteProvider: RewriteProviderType
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
        self.selectedRewriteLevel = RewriteLevel(rawValue: prefs.rewriteLevel) ?? .moderate
        self.selectedTranscriptionProvider = TranscriptionProviderType(rawValue: prefs.transcriptionProvider) ?? .whisper
        self.selectedRewriteProvider = RewriteProviderType(rawValue: prefs.rewriteProvider) ?? .claude
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
            self.playbackBehavior = PlaybackBehavior(rawValue: prefs.playbackBehavior) ?? .pause
        }
    }

    /// Save all current settings to UserPreferences (auto-save)
    func saveToPreferences() {
        let prefs = UserPreferences()
        prefs.rewriteLevel = selectedRewriteLevel.rawValue
        prefs.transcriptionProvider = selectedTranscriptionProvider.rawValue
        prefs.rewriteProvider = selectedRewriteProvider.rawValue
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

    // MARK: - Navigation
    var selectedSidebarItem: SidebarItem = .home
    var isMainWindowOpen: Bool = false

}

// MARK: - Enums

enum RewriteLevel: String, CaseIterable, Codable {
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"

    var description: String {
        switch self {
        case .light: "Remove fillers, fix grammar. Keep your exact phrasing."
        case .moderate: "Clean up and restructure for clarity. Preserve your voice."
        case .heavy: "Full rewrite into polished prose. Reads like you wrote it carefully."
        }
    }

    var promptFileName: String {
        switch self {
        case .light: "light_rewrite"
        case .moderate: "moderate_rewrite"
        case .heavy: "heavy_rewrite"
        }
    }

    var next: RewriteLevel {
        switch self {
        case .light: .moderate
        case .moderate: .heavy
        case .heavy: .light
        }
    }
}

enum PlaybackBehavior: String, CaseIterable, Codable {
    case pause = "Pause"
    case stop = "Stop"
    case doNothing = "Do nothing"
}

enum TranscriptionProviderType: String, CaseIterable, Codable, Identifiable {
    case deepgram = "Deepgram"
    case whisper = "OpenAI Whisper"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .deepgram: "waveform"
        case .whisper: "brain.head.profile"
        }
    }

    var keychainKey: String {
        switch self {
        case .deepgram: "deepgram_api_key"
        case .whisper: "openai_api_key"
        }
    }
}

enum RewriteProviderType: String, CaseIterable, Codable, Identifiable {
    case claude = "Claude"
    case gpt = "GPT"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .claude: "sparkles"
        case .gpt: "brain"
        }
    }

    var keychainKey: String {
        switch self {
        case .claude: "anthropic_api_key"
        case .gpt: "openai_api_key"
        }
    }
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
