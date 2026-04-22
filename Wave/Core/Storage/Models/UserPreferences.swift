import SwiftUI

final class UserPreferences {
    @AppStorage("rewriteLevel") var rewriteLevel: String = RewriteLevel.raw.rawValue
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
    @AppStorage("overlayAnimationStyle") var overlayAnimationStyle: String = OverlayAnimationStyle.smooth.rawValue
    @AppStorage("overlayAnimationSpeed") var overlayAnimationSpeed: Double = 1.0

    // Local LLM selection (Wave-side id from `LocalLLMRegistry.all`)
    @AppStorage("selectedLocalLLMModelId") var selectedLocalLLMModelId: String = ""

    // Idle-unload timeout in seconds. -1 = never. 0 = unload immediately.
    @AppStorage("llmIdleTimeoutSeconds") var llmIdleTimeoutSecondsRaw: Int = 300
}
