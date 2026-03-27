import AppKit
import ApplicationServices

final class AccessibilityManager: @unchecked Sendable {
    static let shared = AccessibilityManager()

    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        // Use the string key directly to avoid Swift 6 concurrency issue with C global
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func isTextFieldFocused() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success, let element = focusedElement else { return false }

        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXRoleAttribute as CFString, &role)

        if let roleString = role as? String {
            let textRoles = [
                kAXTextFieldRole, kAXTextAreaRole,
                "AXWebArea", "AXComboBox", "AXSearchField"
            ]
            return textRoles.contains(roleString)
        }

        return false
    }
}
