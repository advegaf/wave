import SwiftUI
import CoreAudio

struct MainWindowView: View {
    @Bindable var appState: AppState
    var coordinator: RecordingCoordinator

    var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
                .background(Wave.colors.background)
                .frame(minWidth: Wave.window.sidebarWidth)
        } detail: {
            ZStack {
                Wave.colors.surfaceSecondary
                    .ignoresSafeArea()

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: Wave.window.mainWidth,
            minHeight: Wave.window.mainHeight
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                MicrophoneSelector()
            }
        }
        .onAppear { appState.isMainWindowOpen = true }
        .onDisappear { appState.isMainWindowOpen = false }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSidebarItem {
        case .home:
            HomeView(appState: appState, coordinator: coordinator)
        case .modes:
            ModesView(appState: appState)
        case .vocabulary:
            VocabularyView()
        case .snippets:
            SnippetsView()
        case .configuration:
            ConfigurationView(appState: appState)
        case .sound:
            SoundView(appState: appState)
        case .modelsLibrary:
            ModelsLibraryView(appState: appState, coordinator: coordinator)
        case .history:
            HistoryView()
        }
    }
}

// MARK: - Microphone Selector

struct MicrophoneSelector: View {
    @State private var devices: [(id: AudioDeviceID, name: String)] = []
    @State private var selectedDevice: String = "Default"

    var body: some View {
        Menu {
            ForEach(devices, id: \.id) { device in
                Button(device.name) {
                    selectedDevice = device.name
                }
            }
        } label: {
            HStack(spacing: Wave.spacing.s6) {
                Text("\(selectedDevice) (Default)")
                    .waveFont(Wave.font.captionLight)
                    .lineLimit(1)
                Image(systemName: "display")
                    .waveFont(Wave.font.captionLight)
            }
            .foregroundStyle(Wave.colors.textSecondary)
            .padding(.horizontal, Wave.spacing.s12)
            .padding(.vertical, Wave.spacing.s8)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r6))
        }
        .menuStyle(.borderlessButton)
        .onAppear {
            devices = AudioCaptureEngine.availableInputDevices()
            if let first = devices.first {
                selectedDevice = first.name
            }
        }
    }
}
