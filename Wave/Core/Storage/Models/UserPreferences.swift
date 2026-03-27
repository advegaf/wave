import SwiftUI

final class UserPreferences {
    @AppStorage("rewriteLevel") var rewriteLevel: String = RewriteLevel.moderate.rawValue
    @AppStorage("transcriptionProvider") var transcriptionProvider: String = TranscriptionProviderType.deepgram.rawValue
    @AppStorage("rewriteProvider") var rewriteProvider: String = RewriteProviderType.claude.rawValue
    @AppStorage("overlayStyle") var overlayStyle: String = OverlayStyle.full.rawValue
    @AppStorage("silenceTimeout") var silenceTimeout: Double = 3.0
    @AppStorage("soundEffectsEnabled") var soundEffectsEnabled: Bool = true
    @AppStorage("soundEffectsVolume") var soundEffectsVolume: Double = 0.7
    @AppStorage("autoIncreaseVolume") var autoIncreaseVolume: Bool = true
    @AppStorage("silenceRemoval") var silenceRemoval: Bool = false
    @AppStorage("playbackBehavior") var playbackBehavior: String = PlaybackBehavior.doNothing.rawValue
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("overlayPositionY") var overlayPositionY: Double = 10 // px above dock
}
