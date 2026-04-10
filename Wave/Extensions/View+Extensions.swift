import SwiftUI

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Waveform Style Previews

struct WaveformFullPreview: View {
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<20, id: \.self) { i in
                let height = waveformBarHeight(index: i, total: 20)
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.6))
                    .frame(width: 2, height: height)
            }
        }
        .frame(height: 30)
    }

    private func waveformBarHeight(index: Int, total: Int) -> CGFloat {
        let center = CGFloat(total) / 2.0
        let distance = abs(CGFloat(index) - center) / center
        let base = 6 + (1 - distance) * 24
        let variation = CGFloat((index * 7 + 3) % 5) * 1.5
        return max(4, base + variation - 3)
    }
}

struct WaveformMiniPreview: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                let heights: [CGFloat] = [6, 12, 18, 12, 6]
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.6))
                    .frame(width: 3, height: heights[i])
            }
        }
        .frame(height: 20)
    }
}

