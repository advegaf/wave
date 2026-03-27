import SwiftUI

struct SiriWaveView: View {
    let levelMonitor: AudioLevelMonitor
    let style: OverlayStyle

    @State private var data = WaveData()
    @State private var throttleTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            supportBar

            ForEach(0..<3, id: \.self) { i in
                WaveShape(wave: data.waves[i])
                    .fill(data.colors[i])
            }
        }
        .animation(.easeInOut(duration: 0.5), value: data.waves)
        .blendMode(.lighten)
        .drawingGroup(opaque: false)
        .frame(width: style.width, height: style.height)
        .onAppear { startThrottledUpdates() }
        .onDisappear { throttleTask?.cancel() }
    }

    private var supportBar: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0),
                        .init(color: .white.opacity(0.7), location: 0.1),
                        .init(color: .white.opacity(0.7), location: 0.8),
                        .init(color: .white.opacity(0), location: 1.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
        }
    }

    private func startThrottledUpdates() {
        throttleTask?.cancel()
        throttleTask = Task { @MainActor in
            while !Task.isCancelled {
                let power = CGFloat(levelMonitor.smoothedLevel)
                data.update(power: power)
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }
}
