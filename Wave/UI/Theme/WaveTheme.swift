import SwiftUI

enum WaveTheme {
    // MARK: - Colors
    static let background = Color(nsColor: NSColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0))      // #1A1A1A
    static let surfacePrimary = Color(nsColor: NSColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0))   // #242424
    static let surfaceSecondary = Color(nsColor: NSColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)) // #2A2A2A
    static let surfaceHover = Color(nsColor: NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0))     // #333333
    static let border = Color(nsColor: NSColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0))           // #383838

    static let textPrimary = Color.white
    static let textSecondary = Color(nsColor: NSColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1.0))
    static let textTertiary = Color(nsColor: NSColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1.0))

    static let accent = Color.blue
    static let destructive = Color.red
    static let glowColor = Color.white.opacity(0.03)

    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner Radius
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 10
    static let radiusLG: CGFloat = 14
    static let radiusInner: CGFloat = 6 // For nested elements inside cards (concentric: outer - padding/gap)

    // MARK: - Window
    static let sidebarWidth: CGFloat = 200
    static let windowWidth: CGFloat = 714
    static let windowHeight: CGFloat = 480
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WaveTheme.spacingLG)
            .background(WaveTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusMD))
            .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
            .shadow(color: .white.opacity(0.06), radius: 0.5, x: 0, y: 0)
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(WaveTheme.textSecondary)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
}
