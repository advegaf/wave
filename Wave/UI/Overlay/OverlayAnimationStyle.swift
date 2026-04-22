import QuartzCore

enum OverlayAnimationStyle: String, CaseIterable, Codable, Hashable {
    case smooth  = "Smooth"
    case snappy  = "Snappy"
    case bouncy  = "Bouncy"
    case linear  = "Linear"

    var showTimingFunction: CAMediaTimingFunction {
        switch self {
        case .smooth:
            return CAMediaTimingFunction(name: .easeOut)
        case .snappy:
            return CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1)
        case .bouncy:
            return CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1)
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        }
    }

    var hideTimingFunction: CAMediaTimingFunction {
        switch self {
        case .smooth:
            return CAMediaTimingFunction(name: .easeIn)
        case .snappy:
            return CAMediaTimingFunction(controlPoints: 0.8, 0, 0.8, 0.2)
        case .bouncy:
            return CAMediaTimingFunction(name: .easeIn)
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        }
    }
}
