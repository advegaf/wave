import Foundation

enum RecordingState: Equatable {
    case idle
    case activating
    case recording
    case processing
    case pasting
    case cancelling

    var isActive: Bool {
        switch self {
        case .recording, .activating: true
        default: false
        }
    }

    var statusText: String {
        switch self {
        case .idle: "Ready"
        case .activating: "Starting..."
        case .recording: "Listening..."
        case .processing: "Processing..."
        case .pasting: "Inserting..."
        case .cancelling: "Cancelled"
        }
    }
}
