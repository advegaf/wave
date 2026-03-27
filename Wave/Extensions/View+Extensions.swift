import SwiftUI

// MARK: - Stagger Animation Tracking

/// Tracks which screens have already shown their stagger animation
/// so items don't re-animate when revisiting tabs.
private final class StaggerTracker: @unchecked Sendable {
    static let shared = StaggerTracker()
    var appearedScreens: Set<String> = []
}

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

    /// Staggered appear animation for list items (first appear only per screen)
    func staggeredAppear(index: Int, appeared: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(
                .easeOut(duration: 0.3).delay(Double(index) * 0.05),
                value: appeared
            )
    }

}

/// Call in onAppear to trigger stagger only on first visit per screen
func triggerStaggerOnce(for screenId: String, appeared: inout Bool) {
    if StaggerTracker.shared.appearedScreens.contains(screenId) {
        appeared = true
    } else {
        StaggerTracker.shared.appearedScreens.insert(screenId)
        withAnimation { appeared = true }
    }
}

// MARK: - Pressable Card Button Style

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.spring(duration: 0.16), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    static var pressableCard: PressableCardStyle { PressableCardStyle() }
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

// MARK: - Dotted Slider (snap haptics)

struct DottedSlider: View {
    @Binding var value: Float
    var range: ClosedRange<Float> = 0...1
    var steps: Int = 10
    @State private var lastSnap: Int = -1

    var body: some View {
        ZStack(alignment: .center) {
            // Dot indicators
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(0...steps, id: \.self) { _ in
                        Circle()
                            .fill(WaveTheme.textTertiary.opacity(0.5))
                            .frame(width: 3, height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: geo.size.height)
            }

            // Actual slider on top
            Slider(value: $value, in: range)
                .tint(WaveTheme.accent)
                .onChange(of: value) { _, newValue in
                    let currentSnap = Int((newValue - range.lowerBound) / (range.upperBound - range.lowerBound) * Float(steps))
                    if currentSnap != lastSnap {
                        lastSnap = currentSnap
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
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
