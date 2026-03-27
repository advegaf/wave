import AppKit
import CoreGraphics

/// Paste mechanism identical to Superwhisper/Freeflow:
/// clipboard + CGEvent Cmd+V with .hidSystemState source.
final class ClipboardManager {
    private var savedItems: [[NSPasteboard.PasteboardType: Data]] = []

    func pasteText(_ text: String) async {
        // 1. Save current clipboard
        saveClipboard()

        // 2. Set text on clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        // 3. Brief delay for clipboard to settle
        try? await Task.sleep(for: .milliseconds(20))

        // 4. Simulate Cmd+V via CGEvent (same as Superwhisper/Freeflow)
        let source = CGEventSource(stateID: .hidSystemState)
        source?.setLocalEventsFilterDuringSuppressionState(.permitLocalMouseEvents, state: .eventSuppressionStateSuppressionInterval)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            print("[Wave] Failed to create CGEvent — accessibility not granted")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        print("[Wave] Cmd+V posted via CGEvent (.hidSystemState)")

        // 5. Wait for target app to process paste
        try? await Task.sleep(for: .milliseconds(50))

        // 6. Restore original clipboard
        restoreClipboard()
    }

    // MARK: - Clipboard Save/Restore

    private func saveClipboard() {
        savedItems.removeAll()
        guard let items = NSPasteboard.general.pasteboardItems else { return }
        for item in items {
            var itemData: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemData[type] = data
                }
            }
            savedItems.append(itemData)
        }
    }

    private func restoreClipboard() {
        NSPasteboard.general.clearContents()
        for itemData in savedItems {
            let item = NSPasteboardItem()
            for (type, data) in itemData {
                item.setData(data, forType: type)
            }
            NSPasteboard.general.writeObjects([item])
        }
        savedItems.removeAll()
    }
}
