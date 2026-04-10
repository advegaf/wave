// Wave/UI/Theme/WaveTheme.swift
import SwiftUI
import AppKit

/// Namespaced design tokens for Wave's Notion-inspired UI. Every view reads
/// from `Wave.colors`, `Wave.spacing`, `Wave.radius`, `Wave.font`, or
/// `Wave.shadow` — never from hardcoded values.
enum Wave {
    enum colors {}
    enum spacing {}
    enum radius {}
    enum font {}
    enum shadow {}
}

// MARK: - Colors (adaptive light + dark)

extension Wave.colors {
    /// Build an adaptive Color that picks different values per appearance.
    /// Uses an NSColor dynamic provider so appearance changes re-render live.
    static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark]) != nil {
                return dark
            }
            return light
        })
    }

    // Surfaces
    static let background        = adaptive(light: .white,                    dark: NSColor(red: 0.106, green: 0.102, blue: 0.098, alpha: 1.0)) // #1b1a19
    static let surfacePrimary    = adaptive(light: .white,                    dark: NSColor(red: 0.141, green: 0.137, blue: 0.125, alpha: 1.0)) // #242320
    static let surfaceSecondary  = adaptive(light: NSColor(red: 0.965, green: 0.961, blue: 0.957, alpha: 1.0),  // #f6f5f4
                                            dark:  NSColor(red: 0.180, green: 0.173, blue: 0.161, alpha: 1.0)) // #2e2c29
    static let surfaceHover      = adaptive(light: NSColor(red: 0.941, green: 0.933, blue: 0.922, alpha: 1.0),  // #f0eeeb
                                            dark:  NSColor(red: 0.200, green: 0.192, blue: 0.161, alpha: 1.0)) // #333129

    // Text
    static let textPrimary       = adaptive(light: NSColor(white: 0.0, alpha: 0.95),  dark: NSColor(white: 1.0, alpha: 0.95))
    static let textSecondary     = adaptive(light: NSColor(red: 0.380, green: 0.365, blue: 0.349, alpha: 1.0),  // #615d59
                                            dark:  NSColor(red: 0.639, green: 0.620, blue: 0.596, alpha: 1.0)) // #a39e98
    static let textTertiary      = adaptive(light: NSColor(red: 0.639, green: 0.620, blue: 0.596, alpha: 1.0),
                                            dark:  NSColor(red: 0.380, green: 0.365, blue: 0.349, alpha: 1.0))

    // Borders (whisper)
    static let border            = adaptive(light: NSColor(white: 0.0, alpha: 0.10),  dark: NSColor(white: 1.0, alpha: 0.08))

    // Accent (Notion Blue / Link Light Blue in dark)
    static let accent            = adaptive(light: NSColor(red: 0.000, green: 0.459, blue: 0.871, alpha: 1.0),  // #0075de
                                            dark:  NSColor(red: 0.384, green: 0.682, blue: 0.941, alpha: 1.0)) // #62aef0
    static let accentHover       = adaptive(light: NSColor(red: 0.000, green: 0.357, blue: 0.671, alpha: 1.0),  // #005bab
                                            dark:  NSColor(red: 0.035, green: 0.498, blue: 0.910, alpha: 1.0)) // #097fe8

    // Pill badge
    static let badgeBlueBg       = adaptive(light: NSColor(red: 0.949, green: 0.976, blue: 1.000, alpha: 1.0),  // #f2f9ff
                                            dark:  NSColor(red: 0.384, green: 0.682, blue: 0.941, alpha: 0.12))
    static let badgeBlueText     = adaptive(light: NSColor(red: 0.035, green: 0.498, blue: 0.910, alpha: 1.0),
                                            dark:  NSColor(red: 0.384, green: 0.682, blue: 0.941, alpha: 1.0))

    // Semantic
    static let success           = adaptive(light: NSColor(red: 0.102, green: 0.682, blue: 0.224, alpha: 1.0),  // #1aae39
                                            dark:  NSColor(red: 0.259, green: 0.773, blue: 0.380, alpha: 1.0)) // #42c561
    static let warning           = adaptive(light: NSColor(red: 0.867, green: 0.357, blue: 0.000, alpha: 1.0),  // #dd5b00
                                            dark:  NSColor(red: 1.000, green: 0.498, blue: 0.188, alpha: 1.0)) // #ff7f30
    static let destructive       = adaptive(light: NSColor(red: 0.867, green: 0.000, blue: 0.000, alpha: 1.0),
                                            dark:  NSColor(red: 1.000, green: 0.361, blue: 0.361, alpha: 1.0)) // #ff5c5c
}

// MARK: - Spacing (Notion 8-based, extended)

extension Wave.spacing {
    static let s2:  CGFloat =  2
    static let s4:  CGFloat =  4
    static let s6:  CGFloat =  6
    static let s8:  CGFloat =  8
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    static let s48: CGFloat = 48
    static let s64: CGFloat = 64
    static let s80: CGFloat = 80
}

// MARK: - Radius

extension Wave.radius {
    static let r4:    CGFloat =   4
    static let r6:    CGFloat =   6
    static let r8:    CGFloat =   8
    static let r12:   CGFloat =  12
    static let r16:   CGFloat =  16
    static let pill:  CGFloat = 999
}

// MARK: - Typography (SF Pro, desktop-scaled Notion ladder)

extension Wave.font {
    /// (size, weight, tracking) triples for the SF Pro Notion-scale ladder.
    /// `tracking` is points in the SwiftUI sense — apply via `.tracking(...)`.
    struct Style {
        let size: CGFloat
        let weight: Font.Weight
        let tracking: CGFloat
        var swiftUIFont: Font { .system(size: size, weight: weight, design: .default) }
    }

    static let displayHero     = Style(size: 36, weight: .bold,     tracking: -1.2)
    static let displayLarge    = Style(size: 28, weight: .bold,     tracking: -0.8)
    static let displayMedium   = Style(size: 24, weight: .bold,     tracking: -0.6)
    static let sectionHeading  = Style(size: 20, weight: .bold,     tracking: -0.4)
    static let cardTitle       = Style(size: 17, weight: .semibold, tracking: -0.2)
    static let bodyLarge       = Style(size: 15, weight: .medium,   tracking:  0)
    static let body            = Style(size: 13, weight: .regular,  tracking:  0)
    static let bodyMedium      = Style(size: 13, weight: .medium,   tracking:  0)
    static let bodySemibold    = Style(size: 13, weight: .semibold, tracking:  0)
    static let nav             = Style(size: 13, weight: .semibold, tracking:  0)
    static let caption         = Style(size: 11, weight: .medium,   tracking:  0)
    static let captionLight    = Style(size: 11, weight: .regular,  tracking:  0)
    static let badge           = Style(size: 10, weight: .semibold, tracking:  0.3)
    static let micro           = Style(size: 10, weight: .regular,  tracking:  0.2)
}

extension View {
    /// Apply a Wave typography style (size + weight + tracking) in one call.
    func waveFont(_ style: Wave.font.Style) -> some View {
        self.font(style.swiftUIFont).tracking(style.tracking)
    }
}

// MARK: - Window dimensions (preserved from old WaveTheme for WaveApp use)

extension Wave {
    enum window {
        static let sidebarWidth: CGFloat = 220
        static let mainWidth:    CGFloat = 900
        static let mainHeight:   CGFloat = 700
    }
}

