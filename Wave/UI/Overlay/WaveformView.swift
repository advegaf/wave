import SwiftUI

struct WaveformView: View {
    let levelMonitor: AudioLevelMonitor
    let style: OverlayStyle

    var body: some View {
        SiriWaveView(levelMonitor: levelMonitor, style: style)
    }
}
