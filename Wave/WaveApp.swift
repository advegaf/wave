import SwiftUI

@main
struct WaveApp: App {
    @State private var appState = AppState()
    @State private var coordinator = RecordingCoordinator()
    @State private var hotkeyManager = GlobalHotkeyManager()
    @State private var overlayController = OverlayWindowController()

    var body: some Scene {
        // Menu Bar
        MenuBarExtra {
            MenuBarView(
                appState: appState,
                coordinator: coordinator
            )
        } label: {
            Image(systemName: "waveform")
        }
        .menuBarExtraStyle(.window)

        // Main Window
        Window("Wave", id: "main") {
            Group {
                if appState.hasCompletedSetup {
                    MainWindowView(appState: appState, coordinator: coordinator)
                } else {
                    SetupWizardView(appState: appState)
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: appState.overlayStyle) { syncCoordinatorSettings() }
            .onChange(of: appState.overlayPositionY) { syncCoordinatorSettings() }
            .onChange(of: appState.selectedRewriteLevel) { syncCoordinatorSettings() }
            .onChange(of: appState.selectedLocalLLMModelId) { syncCoordinatorSettings() }
            .onChange(of: appState.llmIdleTimeoutSeconds) { syncCoordinatorSettings() }
            .onChange(of: appState.soundEffectsEnabled) { syncCoordinatorSettings() }
            .onChange(of: appState.soundEffectsVolume) { syncCoordinatorSettings() }
            .onChange(of: appState.playbackBehavior) { syncCoordinatorSettings() }
        }
        .defaultSize(width: Wave.window.mainWidth, height: Wave.window.mainHeight)
        .windowResizability(.contentSize)
    }

    init() {
        setupDatabase()
        syncCoordinatorSettings()
        setupOverlay()
        setupHotkeys()
        coordinator.preloadWhisperModel(appState: appState)
    }

    private func setupDatabase() {
        do {
            try DatabaseManager.shared.setup()
        } catch {
            print("[Wave] Database setup failed: \(error)")
        }
    }

    private func setupHotkeys() {
        hotkeyManager.onToggleRecording = { [coordinator] in
            coordinator.toggleRecording()
        }

        hotkeyManager.onCancelRecording = { [coordinator] in
            coordinator.cancelRecording()
        }

        hotkeyManager.onPushToTalkStart = { [coordinator] in
            coordinator.startPushToTalk()
        }

        hotkeyManager.onPushToTalkEnd = { [coordinator] in
            coordinator.stopPushToTalk()
        }

        hotkeyManager.onChangeRewriteLevel = { [appState] in
            appState.selectedRewriteLevel = appState.selectedRewriteLevel.next
            appState.saveToPreferences()
        }

        hotkeyManager.setup()
    }

    private func syncCoordinatorSettings() {
        coordinator.rewriteLevel = appState.selectedRewriteLevel
        coordinator.selectedLocalLLMModelId = appState.selectedLocalLLMModelId
        coordinator.llmIdleTimeoutSeconds = appState.llmIdleTimeoutSeconds
        coordinator.soundEffectsEnabled = appState.soundEffectsEnabled
        coordinator.soundEffectsVolume = appState.soundEffectsVolume
        coordinator.playbackBehavior = appState.playbackBehavior
        coordinator.overlayStyle = appState.overlayStyle
        coordinator.overlayPositionY = appState.overlayPositionY
    }

    private func setupOverlay() {
        overlayController.overlayStyle = appState.overlayStyle
        coordinator.overlayController = overlayController
        coordinator.hotkeyManager = hotkeyManager
    }
}
