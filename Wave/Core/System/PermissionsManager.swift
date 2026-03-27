import AVFoundation
import Observation

@Observable
final class PermissionsManager: @unchecked Sendable {
    var microphoneGranted = false
    var accessibilityGranted = false

    func checkAll() {
        checkMicrophone()
        checkAccessibility()
    }

    func checkMicrophone() {
        microphoneGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestMicrophone() async -> Bool {
        let granted = await AudioSessionManager.shared.requestMicrophonePermission()
        microphoneGranted = granted
        return granted
    }

    func requestAccessibility() {
        AccessibilityManager.shared.requestAccessibilityPermission()
        // Poll in background until granted
        pollAccessibility()
    }

    private func pollAccessibility() {
        let manager = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            manager.checkAccessibility()
            if !manager.accessibilityGranted {
                manager.pollAccessibility()
            }
        }
    }

    var allPermissionsGranted: Bool {
        microphoneGranted && accessibilityGranted
    }
}
