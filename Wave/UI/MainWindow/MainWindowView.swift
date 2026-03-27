import SwiftUI
import CoreAudio

struct MainWindowView: View {
    @Bindable var appState: AppState
    var coordinator: RecordingCoordinator

    var body: some View {
        NavigationSplitView {
            SidebarView(appState: appState)
        } detail: {
            ZStack {
                // Background with subtle bottom glow
                WaveTheme.background
                    .ignoresSafeArea()

                RadialGradient(
                    colors: [WaveTheme.glowColor, .clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()

                detailView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(
            minWidth: WaveTheme.windowWidth,
            minHeight: WaveTheme.windowHeight
        )
        .toolbar {
            ToolbarItem(placement: .automatic) {
                MicrophoneSelector()
            }
        }
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
            HStack(spacing: 6) {
                Text("\(selectedDevice) (Default)")
                    .font(.system(size: 11))
                    .lineLimit(1)
                Image(systemName: "display")
                    .font(.system(size: 10))
            }
            .foregroundStyle(WaveTheme.textSecondary)
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)
            .background(WaveTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusSM))
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
