import ServiceManagement

final class LaunchAtLoginManager: @unchecked Sendable {
    static let shared = LaunchAtLoginManager()

    var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[LaunchAtLogin] Failed to update: \(error)")
            }
        }
    }
}
