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

// MARK: - Help Tooltip Icon

struct HelpTooltipIcon: View {
    let text: String
    @State private var isShowing = false

    var body: some View {
        Button {
            isShowing.toggle()
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 12))
                .foregroundStyle(WaveTheme.textTertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowing, arrowEdge: .bottom) {
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(WaveTheme.textSecondary)
                .padding(WaveTheme.spacingMD)
                .frame(maxWidth: 240)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Dotted Slider (compact, matching Superwhisper)

struct DottedSlider: View {
    @Binding var value: Float
    var range: ClosedRange<Float> = 0...1
    var steps: Int = 10
    @State private var lastSnap: Int = -1

    var body: some View {
        VStack(spacing: 2) {
            Slider(value: $value, in: range)
                .tint(WaveTheme.accent)
                .controlSize(.small)
                .onChange(of: value) { _, newValue in
                    let currentSnap = Int((newValue - range.lowerBound) / (range.upperBound - range.lowerBound) * Float(steps))
                    if currentSnap != lastSnap {
                        lastSnap = currentSnap
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    }
                }

            // Dots below the slider track
            HStack(spacing: 0) {
                ForEach(0...steps, id: \.self) { _ in
                    Circle()
                        .fill(WaveTheme.textTertiary.opacity(0.4))
                        .frame(width: 2.5, height: 2.5)
                        .frame(maxWidth: .infinity)
                }
            }
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

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: WaveTheme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(WaveTheme.textTertiary)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(WaveTheme.textSecondary)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(WaveTheme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, WaveTheme.spacingXS)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
