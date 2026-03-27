import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.space, modifiers: [.command, .shift]))
    static let pushToTalk = Self("pushToTalk")
    static let changeRewriteLevel = Self("changeRewriteLevel", default: .init(.k, modifiers: [.command, .shift, .option]))
}

final class GlobalHotkeyManager {
    var onToggleRecording: (() -> Void)?
    var onCancelRecording: (() -> Void)?
    var onPushToTalkStart: (() -> Void)?
    var onPushToTalkEnd: (() -> Void)?
    var onChangeRewriteLevel: (() -> Void)?

    private var escapeMonitor: Any?

    func setup() {
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            self?.onToggleRecording?()
        }

        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            self?.onPushToTalkStart?()
        }

        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            self?.onPushToTalkEnd?()
        }

        KeyboardShortcuts.onKeyUp(for: .changeRewriteLevel) { [weak self] in
            self?.onChangeRewriteLevel?()
        }
    }

    func startListeningForEscape() {
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.onCancelRecording?()
            }
        }
    }

    func stopListeningForEscape() {
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }

    deinit {
        stopListeningForEscape()
    }
}
