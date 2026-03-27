import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<WaveformView>?

    var overlayStyle: OverlayStyle = .full
    var positionY: CGFloat = 10  // px above the dock/bottom of visible frame

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

        let panel = NSPanel(
            contentRect: NSRect(x: xPos, y: startY, width: width, height: height),
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

        panel.orderFrontRegardless()

        self.panel = panel
        self.hostingView = hosting

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
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

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
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
