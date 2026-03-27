import AppKit

final class ActiveAppDetector {
    private var cachedAppName: String?
    private var cachedApp: NSRunningApplication?

    var currentAppName: String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    func captureActiveApp() {
        cachedApp = NSWorkspace.shared.frontmostApplication
        cachedAppName = cachedApp?.localizedName
    }

    /// Re-activate the app that was active when recording started
    func reactivateCapturedApp() {
        cachedApp?.activate()
    }

    var capturedAppName: String {
        cachedAppName ?? currentAppName
    }

    var isMessagingApp: Bool {
        let messagingApps = ["Slack", "Discord", "Messages", "Telegram", "WhatsApp", "Signal"]
        return messagingApps.contains(where: { capturedAppName.localizedCaseInsensitiveContains($0) })
    }

    var isEmailApp: Bool {
        let emailApps = ["Mail", "Outlook", "Gmail", "Spark", "Airmail", "Superhuman"]
        return emailApps.contains(where: { capturedAppName.localizedCaseInsensitiveContains($0) })
    }

    var isCodeEditor: Bool {
        let codeEditors = ["Xcode", "Visual Studio Code", "Code", "Cursor", "Sublime Text", "Vim", "Neovim", "Terminal", "iTerm"]
        return codeEditors.contains(where: { capturedAppName.localizedCaseInsensitiveContains($0) })
    }

    var suggestedTone: String {
        if isMessagingApp { return "casual and conversational" }
        if isEmailApp { return "professional and clear" }
        if isCodeEditor { return "technical and precise" }
        return "clear and natural"
    }

    func reset() {
        cachedAppName = nil
        cachedApp = nil
    }
}
