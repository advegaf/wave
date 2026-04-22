import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<WaveformView>?

    var overlayStyle: OverlayStyle = .full
    var positionY: CGFloat = 10  // px above the dock/bottom of visible frame
    var animationStyle: OverlayAnimationStyle = .smooth
    var animationSpeed: Double = 1.0  // multiplier on base 0.4s show / 0.3s hide

    private static let baseShowDuration: Double = 0.4
    private static let baseHideDuration: Double = 0.3

    private var reduceMotionEnabled: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    func show(levelMonitor: AudioLevelMonitor) {
        guard panel == nil else { return }

        let waveformView = WaveformView(
            levelMonitor: levelMonitor,
            style: overlayStyle
        )

        let width = overlayStyle.width
        let height = overlayStyle.height

        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let xPos = visibleFrame.midX - width / 2
        let startY = visibleFrame.minY - height
        let endY = visibleFrame.minY + positionY

        // Capture animation settings at the start of this animation so any
        // mid-flight setting changes don't affect the in-progress show.
        let reduceMotion = reduceMotionEnabled
        let style = animationStyle
        let speed = animationSpeed
        let initialY = reduceMotion ? endY : startY

        let panel = NSPanel(
            contentRect: NSRect(x: xPos, y: initialY, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = NSHostingView(rootView: waveformView)
        hosting.frame = NSRect(x: 0, y: 0, width: width, height: height)
        panel.contentView = hosting

        if reduceMotion {
            panel.alphaValue = 0
        }

        panel.orderFrontRegardless()

        self.panel = panel
        self.hostingView = hosting

        if reduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0
                panel.animator().alphaValue = 1
            }
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.baseShowDuration * speed
            context.timingFunction = style.showTimingFunction
            panel.animator().setFrame(
                NSRect(x: xPos, y: endY, width: width, height: height),
                display: true
            )
        }
    }

    func hide() {
        guard let panel else { return }

        guard let screen = NSScreen.main else {
            dismissPanel()
            return
        }

        let width = overlayStyle.width
        let height = overlayStyle.height
        let xPos = screen.visibleFrame.midX - width / 2
        let endY = screen.visibleFrame.minY - height

        let reduceMotion = reduceMotionEnabled
        let style = animationStyle
        let speed = animationSpeed

        if reduceMotion {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0
                panel.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor [weak self] in
                    self?.dismissPanel()
                }
            })
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Self.baseHideDuration * speed
            context.timingFunction = style.hideTimingFunction
            panel.animator().setFrame(
                NSRect(x: xPos, y: endY, width: width, height: height),
                display: true
            )
        }, completionHandler: {
            Task { @MainActor [weak self] in
                self?.dismissPanel()
            }
        })
    }

    private func dismissPanel() {
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
    }
}
