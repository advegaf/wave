# Notion UI Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Wave's UI in the Notion design language (warm neutrals, whisper borders, multi-layer shadows, Notion type ladder) as a system-aware light/dark theme, across the main window, menu bar popover, and setup wizard. Overlay stays untouched.

**Architecture:** Phased per-surface delivery, 14 compilable checkpoints. Phase 1 replaces `WaveTheme.swift` with a new token system (`Wave.colors/spacing/radius/font/shadow`) exposing adaptive NSColor-backed values via `Color(light:dark:)`. Phase 2 adds a component library under `Wave/UI/Theme/Components/`. Phases 3–13 rewrite each in-scope view to consume the new tokens/components. Phase 14 is a polish pass.

**Tech Stack:** SwiftUI, macOS 26, SF Pro (system font), `NSColor` dynamic providers for theme-aware colors, multi-layer `.shadow()` modifiers for Notion-style depth, Xcode 26 build toolchain, XcodeGen (`project.yml`).

**Reference spec:** `docs/superpowers/specs/2026-04-09-notion-ui-redesign-design.md` — consult for the complete design rationale, color tables, typography scale, and layout notes per surface. This plan is the executable form.

---

## Global conventions (apply to every task)

- **Build command** (Debug, no signing): `xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build`
- **Regenerate project** after creating new Swift files: `xcodegen generate` (XcodeGen picks up new files under `Wave/` automatically but needs to be re-run).
- **Commit after every task** with a scoped message: `git commit -m "ui: <what>"`
- **Typography accessors** always go through `Wave.font.*` — never use raw `.font(.system(size:))` in view code.
- **Color accessors** always go through `Wave.colors.*` — never use raw `Color.blue`, `.gray`, hex literals, etc.
- **Borders** always via `.whisperBorder()` modifier — never inline `.stroke`.
- **Shadows** always via `.softCardShadow()` or `.deepCardShadow()` — never inline `.shadow()` except inside those modifiers.
- **Visual verification** at each phase: build, install via ad-hoc signing, launch, visually inspect light and dark modes. Ad-hoc install command:
  ```bash
  osascript -e 'tell application "Wave" to quit' 2>/dev/null; sleep 1
  xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Release -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual CODE_SIGNING_REQUIRED=YES DEVELOPMENT_TEAM="" build
  rm -rf /Applications/Wave.app
  cp -R /Users/advegaf/Library/Developer/Xcode/DerivedData/Wave-*/Build/Products/Release/Wave.app /Applications/Wave.app
  open /Applications/Wave.app
  ```

---

## Phase 1 — Rewrite `WaveTheme.swift` with token system

**Files:**
- Modify: `Wave/UI/Theme/WaveTheme.swift` (full rewrite, ~68 lines → ~250 lines)

### Task 1.1: Rewrite WaveTheme with Notion token namespaces

- [ ] **Step 1: Replace `WaveTheme.swift` entirely with the new token system**

```swift
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
        static let mainWidth:    CGFloat = 780
        static let mainHeight:   CGFloat = 520
    }
}

// MARK: - Legacy shims (temporary — removed in Phase 14)
// During the phased migration, existing views still reference `WaveTheme.xyz`.
// Keep these shims so old code compiles while we migrate view-by-view.

enum WaveTheme {
    static let background        = Wave.colors.background
    static let surfacePrimary    = Wave.colors.surfacePrimary
    static let surfaceSecondary  = Wave.colors.surfaceSecondary
    static let surfaceHover      = Wave.colors.surfaceHover
    static let textPrimary       = Wave.colors.textPrimary
    static let textSecondary     = Wave.colors.textSecondary
    static let textTertiary      = Wave.colors.textTertiary
    static let border            = Wave.colors.border
    static let accent            = Wave.colors.accent
    static let destructive       = Wave.colors.destructive
    static let glowColor         = Color.white.opacity(0.03)  // unused by new components but referenced by MainWindowView until phase 5

    static let spacingXS:  CGFloat = Wave.spacing.s4
    static let spacingSM:  CGFloat = Wave.spacing.s8
    static let spacingMD:  CGFloat = Wave.spacing.s12
    static let spacingLG:  CGFloat = Wave.spacing.s16
    static let spacingXL:  CGFloat = Wave.spacing.s24
    static let spacingXXL: CGFloat = Wave.spacing.s32

    static let radiusSM:    CGFloat = Wave.radius.r6
    static let radiusMD:    CGFloat = Wave.radius.r12
    static let radiusLG:    CGFloat = Wave.radius.r16
    static let radiusInner: CGFloat = Wave.radius.r8

    static let sidebarWidth: CGFloat = Wave.window.sidebarWidth
    static let windowWidth:  CGFloat = Wave.window.mainWidth
    static let windowHeight: CGFloat = Wave.window.mainHeight
}

// MARK: - Legacy CardStyle shim (updated to use new tokens under the hood)
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Wave.spacing.s16)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r12))
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(Wave.colors.border, lineWidth: 1)
            )
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .waveFont(Wave.font.caption)
            .foregroundStyle(Wave.colors.textSecondary)
            .textCase(.uppercase)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func sectionHeader() -> some View { modifier(SectionHeaderStyle()) }
}
```

- [ ] **Step 2: Build and verify green**

Run: `xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`. The legacy `WaveTheme` shim keeps every existing view compiling while we migrate them one at a time.

- [ ] **Step 3: Visually verify token adoption by running the app**

Ad-hoc install and launch via the command in Global Conventions. Open the main window and any view. Text should already look subtly different (tracking applied via `waveFont` in the shim's `SectionHeaderStyle`). Colors will still look mostly the same because every existing view uses `WaveTheme.xxx` which now points at the new adaptive values — with one critical difference: toggle macOS appearance (System Settings → Appearance → Light/Dark). Wave should now re-render adaptively. Existing views will look half-migrated in light mode (they weren't designed for light backgrounds); that's expected — Phase 3+ rewrites them.

- [ ] **Step 4: Commit**

```bash
git add Wave/UI/Theme/WaveTheme.swift
git commit -m "ui: rewrite WaveTheme with Notion token system + legacy shim"
```

---

## Phase 2 — Build the component library

**Files:**
- Create: `Wave/UI/Theme/Modifiers/WhisperBorder.swift`
- Create: `Wave/UI/Theme/Modifiers/SoftCardShadow.swift`
- Create: `Wave/UI/Theme/Modifiers/DeepCardShadow.swift`
- Create: `Wave/UI/Theme/Components/WaveButton.swift`
- Create: `Wave/UI/Theme/Components/WavePillBadge.swift`
- Create: `Wave/UI/Theme/Components/WaveCard.swift`
- Create: `Wave/UI/Theme/Components/WaveSectionHeader.swift`
- Create: `Wave/UI/Theme/Components/WaveEmptyState.swift`
- Create: `Wave/UI/Theme/Components/WaveChip.swift`
- Create: `Wave/UI/Theme/Components/WaveSettingRow.swift`
- Create: `Wave/UI/Theme/Components/WaveListItem.swift`
- Create: `Wave/UI/Theme/Components/WaveSegmentedControl.swift`
- Create: `Wave/UI/Theme/Components/WaveDottedSlider.swift`
- Create: `Wave/UI/Theme/Components/WaveHelpTooltip.swift`
- Create: `Wave/UI/Theme/Components/WaveProviderIcon.swift`

### Task 2.1: Modifiers (borders + shadows)

- [ ] **Step 1: Create `WhisperBorder.swift`**

```swift
// Wave/UI/Theme/Modifiers/WhisperBorder.swift
import SwiftUI

struct WhisperBorder: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Wave.colors.border, lineWidth: 1)
        )
    }
}

extension View {
    /// 1 pt whisper-weight border using `Wave.colors.border`. Default radius matches `Wave.radius.r12`.
    func whisperBorder(radius: CGFloat = Wave.radius.r12) -> some View {
        modifier(WhisperBorder(radius: radius))
    }
}
```

- [ ] **Step 2: Create `SoftCardShadow.swift`**

```swift
// Wave/UI/Theme/Modifiers/SoftCardShadow.swift
import SwiftUI

struct SoftCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.04),  radius: 18,   y: 4)
            .shadow(color: .black.opacity(0.027), radius: 7.85, y: 2.025)
            .shadow(color: .black.opacity(0.02),  radius: 2.93, y: 0.8)
            .shadow(color: .black.opacity(0.01),  radius: 1.04, y: 0.175)
    }
}

extension View {
    /// 4-layer ambient shadow stack — the standard card elevation.
    func softCardShadow() -> some View { modifier(SoftCardShadow()) }
}
```

- [ ] **Step 3: Create `DeepCardShadow.swift`**

```swift
// Wave/UI/Theme/Modifiers/DeepCardShadow.swift
import SwiftUI

struct DeepCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.01), radius: 3,  y: 1)
            .shadow(color: .black.opacity(0.02), radius: 7,  y: 3)
            .shadow(color: .black.opacity(0.02), radius: 15, y: 7)
            .shadow(color: .black.opacity(0.04), radius: 28, y: 14)
            .shadow(color: .black.opacity(0.05), radius: 52, y: 23)
    }
}

extension View {
    /// 5-layer deep shadow stack — for modals, hero cards, setup wizard panels.
    func deepCardShadow() -> some View { modifier(DeepCardShadow()) }
}
```

- [ ] **Step 4: Regenerate project and build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Wave/UI/Theme/Modifiers/
git commit -m "ui: add whisper border + multi-layer shadow modifiers"
```

### Task 2.2: WaveCard + WaveButton

- [ ] **Step 1: Create `WaveCard.swift`**

```swift
// Wave/UI/Theme/Components/WaveCard.swift
import SwiftUI

enum WaveCardStyle { case standard, hero }

/// Standard Notion-style card: surfacePrimary background, whisper border,
/// 12 pt radius, soft 4-layer shadow. Pass `.hero` for 16 pt radius + deep shadow
/// (setup wizard, dashboard hero blocks).
struct WaveCard<Content: View>: View {
    let style: WaveCardStyle
    let padding: CGFloat
    let content: () -> Content

    init(style: WaveCardStyle = .standard, padding: CGFloat = Wave.spacing.s16, @ViewBuilder content: @escaping () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content
    }

    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return Wave.radius.r12
        case .hero:     return Wave.radius.r16
        }
    }

    var body: some View {
        content()
            .padding(padding)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .whisperBorder(radius: cornerRadius)
            .modifier(CardShadowModifier(style: style))
    }
}

private struct CardShadowModifier: ViewModifier {
    let style: WaveCardStyle
    func body(content: Content) -> some View {
        switch style {
        case .standard: content.softCardShadow()
        case .hero:     content.deepCardShadow()
        }
    }
}
```

- [ ] **Step 2: Create `WaveButton.swift`**

```swift
// Wave/UI/Theme/Components/WaveButton.swift
import SwiftUI

enum WaveButtonStyleKind { case primary, secondary, ghost }

struct WaveButton: View {
    let title: String
    let icon: String?
    let kind: WaveButtonStyleKind
    let action: () -> Void

    init(_ title: String, icon: String? = nil, kind: WaveButtonStyleKind = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.kind = kind
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Wave.spacing.s6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .waveFont(Wave.font.nav)
        }
        .buttonStyle(WaveButtonInternalStyle(kind: kind))
    }
}

private struct WaveButtonInternalStyle: ButtonStyle {
    let kind: WaveButtonStyleKind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical,   Wave.spacing.s8)
            .background(background(pressed: configuration.isPressed))
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
            .overlay(borderOverlay)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }

    @ViewBuilder private func background(pressed: Bool) -> some View {
        switch kind {
        case .primary:
            (pressed ? Wave.colors.accentHover : Wave.colors.accent)
        case .secondary:
            Wave.colors.surfaceSecondary
        case .ghost:
            Color.clear
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary:   return .white
        case .secondary: return Wave.colors.textPrimary
        case .ghost:     return Wave.colors.accent
        }
    }

    @ViewBuilder private var borderOverlay: some View {
        switch kind {
        case .secondary:
            RoundedRectangle(cornerRadius: Wave.radius.r4)
                .stroke(Wave.colors.border, lineWidth: 1)
        case .primary, .ghost:
            EmptyView()
        }
    }
}
```

- [ ] **Step 3: Regenerate + build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Wave/UI/Theme/Components/WaveCard.swift Wave/UI/Theme/Components/WaveButton.swift
git commit -m "ui: add WaveCard + WaveButton components"
```

### Task 2.3: WavePillBadge + WaveChip + WaveSectionHeader

- [ ] **Step 1: Create `WavePillBadge.swift`**

```swift
// Wave/UI/Theme/Components/WavePillBadge.swift
import SwiftUI

struct WavePillBadge: View {
    let text: String
    let tone: Tone

    enum Tone {
        case info, success, warning, destructive, neutral
    }

    init(_ text: String, tone: Tone = .info) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text)
            .waveFont(Wave.font.badge)
            .foregroundStyle(foreground)
            .padding(.horizontal, Wave.spacing.s8)
            .padding(.vertical, Wave.spacing.s4)
            .background(background)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch tone {
        case .info:        return Wave.colors.badgeBlueBg
        case .success:     return Wave.colors.success.opacity(0.12)
        case .warning:     return Wave.colors.warning.opacity(0.12)
        case .destructive: return Wave.colors.destructive.opacity(0.12)
        case .neutral:     return Wave.colors.surfaceSecondary
        }
    }

    private var foreground: Color {
        switch tone {
        case .info:        return Wave.colors.badgeBlueText
        case .success:     return Wave.colors.success
        case .warning:     return Wave.colors.warning
        case .destructive: return Wave.colors.destructive
        case .neutral:     return Wave.colors.textSecondary
        }
    }
}
```

- [ ] **Step 2: Create `WaveChip.swift`**

```swift
// Wave/UI/Theme/Components/WaveChip.swift
import SwiftUI

struct WaveChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .waveFont(Wave.font.caption)
                .padding(.horizontal, Wave.spacing.s12)
                .padding(.vertical, Wave.spacing.s6)
                .background(isSelected ? Wave.colors.accent.opacity(0.12) : Wave.colors.surfaceSecondary)
                .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Wave.colors.accent.opacity(0.4) : Wave.colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 3: Create `WaveSectionHeader.swift`**

```swift
// Wave/UI/Theme/Components/WaveSectionHeader.swift
import SwiftUI

struct WaveSectionHeader: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Wave.spacing.s12) {
            VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                Text(title)
                    .waveFont(Wave.font.sectionHeading)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.body)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}
```

- [ ] **Step 4: Regenerate + build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Wave/UI/Theme/Components/WavePillBadge.swift \
        Wave/UI/Theme/Components/WaveChip.swift \
        Wave/UI/Theme/Components/WaveSectionHeader.swift
git commit -m "ui: add WavePillBadge + WaveChip + WaveSectionHeader"
```

### Task 2.4: WaveEmptyState + WaveSettingRow + WaveListItem

- [ ] **Step 1: Create `WaveEmptyState.swift`**

```swift
// Wave/UI/Theme/Components/WaveEmptyState.swift
import SwiftUI

struct WaveEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let primaryAction: (title: String, action: () -> Void)?

    init(icon: String, title: String, subtitle: String? = nil, primaryAction: (title: String, action: () -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.primaryAction = primaryAction
    }

    var body: some View {
        VStack(spacing: Wave.spacing.s16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(Wave.colors.textTertiary)
            Text(title)
                .waveFont(Wave.font.cardTitle)
                .foregroundStyle(Wave.colors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let primaryAction {
                WaveButton(primaryAction.title, kind: .primary, action: primaryAction.action)
                    .padding(.top, Wave.spacing.s8)
            }
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 2: Create `WaveSettingRow.swift`**

```swift
// Wave/UI/Theme/Components/WaveSettingRow.swift
import SwiftUI

struct WaveSettingRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: Wave.spacing.s16) {
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, Wave.spacing.s8)
    }
}
```

- [ ] **Step 3: Create `WaveListItem.swift`**

```swift
// Wave/UI/Theme/Components/WaveListItem.swift
import SwiftUI

struct WaveListItem<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let leading: String?    // SF Symbol
    let accessory: () -> Accessory
    let onTap: (() -> Void)?

    @State private var isHovering = false

    init(
        title: String,
        subtitle: String? = nil,
        leading: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.onTap = onTap
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: Wave.spacing.s12) {
            if let leading {
                Image(systemName: leading)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .frame(width: 16)
            }
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            accessory()
        }
        .padding(.horizontal, Wave.spacing.s12)
        .padding(.vertical, Wave.spacing.s10)
        .background(isHovering ? Wave.colors.surfaceHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { onTap?() }
    }
}

// Also add the missing `s10` spacing value via an extension on Wave.spacing
extension Wave.spacing {
    static let s10: CGFloat = 10
}
```

- [ ] **Step 4: Regenerate + build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Wave/UI/Theme/Components/WaveEmptyState.swift \
        Wave/UI/Theme/Components/WaveSettingRow.swift \
        Wave/UI/Theme/Components/WaveListItem.swift \
        Wave/UI/Theme/WaveTheme.swift
git commit -m "ui: add WaveEmptyState + WaveSettingRow + WaveListItem"
```

### Task 2.5: WaveSegmentedControl

- [ ] **Step 1: Create `WaveSegmentedControl.swift`**

```swift
// Wave/UI/Theme/Components/WaveSegmentedControl.swift
import SwiftUI

/// A pill-shaped segmented control optimized for narrow popovers like the menu bar.
/// Generic over any `Hashable, CaseIterable, RawRepresentable` enum whose `RawValue` is `String`.
struct WaveSegmentedControl<T>: View where T: Hashable & CaseIterable & RawRepresentable, T.RawValue == String, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    @Namespace private var selectionNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { option in
                let isSelected = option == selection
                Text(option.rawValue)
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(isSelected ? Wave.colors.textPrimary : Wave.colors.textSecondary)
                    .padding(.horizontal, Wave.spacing.s12)
                    .padding(.vertical, Wave.spacing.s6)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Wave.colors.surfacePrimary)
                                    .matchedGeometryEffect(id: "selection", in: selectionNS)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selection = option
                        }
                    }
            }
        }
        .padding(Wave.spacing.s2)
        .background(Wave.colors.surfaceSecondary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Wave.colors.border, lineWidth: 1))
    }
}
```

- [ ] **Step 2: Regenerate + build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add Wave/UI/Theme/Components/WaveSegmentedControl.swift
git commit -m "ui: add WaveSegmentedControl"
```

### Task 2.6: WaveDottedSlider + WaveHelpTooltip + WaveProviderIcon

- [ ] **Step 1: Create `WaveDottedSlider.swift`** — port the existing DottedSlider from `Wave/Extensions/View+Extensions.swift` into the new file, replacing all color/spacing/font references with `Wave.colors/spacing/font.*`.

```swift
// Wave/UI/Theme/Components/WaveDottedSlider.swift
import SwiftUI

struct WaveDottedSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Wave.colors.surfaceSecondary)
                    .frame(height: 4)
                // Fill
                Capsule()
                    .fill(Wave.colors.accent)
                    .frame(width: fillWidth(total: geo.size.width), height: 4)
                // Knob
                Circle()
                    .fill(Wave.colors.surfacePrimary)
                    .overlay(Circle().stroke(Wave.colors.accent, lineWidth: 2))
                    .softCardShadow()
                    .frame(width: 14, height: 14)
                    .offset(x: fillWidth(total: geo.size.width) - 7)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let pct = min(max(gesture.location.x / geo.size.width, 0), 1)
                                let raw = range.lowerBound + pct * (range.upperBound - range.lowerBound)
                                let stepped = (raw / step).rounded() * step
                                value = stepped
                            }
                    )
            }
            .frame(height: 14)
        }
        .frame(height: 14)
    }

    private func fillWidth(total: CGFloat) -> CGFloat {
        let pct = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(pct) * total
    }
}
```

- [ ] **Step 2: Create `WaveHelpTooltip.swift`**

```swift
// Wave/UI/Theme/Components/WaveHelpTooltip.swift
import SwiftUI

struct WaveHelpTooltip: View {
    let helpText: String
    @State private var isShowing = false

    var body: some View {
        Button(action: { isShowing.toggle() }) {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Wave.colors.textTertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowing) {
            Text(helpText)
                .waveFont(Wave.font.captionLight)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(Wave.spacing.s12)
                .frame(maxWidth: 260)
        }
    }
}
```

- [ ] **Step 3: Create `WaveProviderIcon.swift`** (replaces the inline `ProviderIcon` SwiftUI struct currently in `AIModelConfig.swift`)

```swift
// Wave/UI/Theme/Components/WaveProviderIcon.swift
import SwiftUI

struct WaveProviderIcon: View {
    let model: AIModelConfig
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Wave.radius.r6)
                .fill(model.providerColor.opacity(0.15))
            Group {
                if let nsImage = NSImage(named: model.providerIconName) {
                    Image(nsImage: nsImage).resizable().scaledToFit().padding(4)
                } else {
                    Image(systemName: model.providerSystemIcon)
                        .foregroundStyle(model.providerColor)
                }
            }
            .padding(4)
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 4: Remove the old `ProviderIcon` struct from `AIModelConfig.swift`** — the data struct stays, only the SwiftUI view at the bottom goes.

Edit `Wave/Core/Storage/Models/AIModelConfig.swift` and delete lines 89–109 (the `// MARK: - Provider Icon View (tries asset, falls back to SF Symbol)` section through the end of the `ProviderIcon` struct). Leave the `AIModelConfig` struct and all its properties intact.

- [ ] **Step 5: Update call sites that reference `ProviderIcon` to use `WaveProviderIcon`**

Run: `grep -rn "ProviderIcon(" Wave/ --include="*.swift"`
For each match, replace `ProviderIcon(` with `WaveProviderIcon(`. Expected matches are in `ModelsLibraryView.swift` and possibly `ModelCard.swift` — just those two files.

- [ ] **Step 6: Regenerate + build**

Run: `xcodegen generate && xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add Wave/UI/Theme/Components/WaveDottedSlider.swift \
        Wave/UI/Theme/Components/WaveHelpTooltip.swift \
        Wave/UI/Theme/Components/WaveProviderIcon.swift \
        Wave/Core/Storage/Models/AIModelConfig.swift \
        Wave/UI/MainWindow/ModelsLibrary/ModelsLibraryView.swift \
        Wave/UI/MainWindow/ModelsLibrary/ModelCard.swift
git commit -m "ui: add WaveDottedSlider/HelpTooltip/ProviderIcon; migrate ProviderIcon out of AIModelConfig"
```

---

## Phase 3 — Rewrite menu bar popover

**Files:**
- Modify: `Wave/UI/MenuBar/MenuBarView.swift` (~149 lines → rewritten, similar line count)

### Task 3.1: Rewrite MenuBarView with new components

- [ ] **Step 1: Rewrite the contents of `MenuBarView.swift`**

Keep the top-level struct signature `struct MenuBarView: View { @Bindable var appState: AppState; var coordinator: RecordingCoordinator; ... }`. The body becomes:

```swift
// Wave/UI/MenuBar/MenuBarView.swift
import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    var coordinator: RecordingCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            HStack(spacing: Wave.spacing.s8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(Wave.colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.top, Wave.spacing.s12)
            .padding(.bottom, Wave.spacing.s8)

            Divider().foregroundStyle(Wave.colors.border)

            // Start/stop recording
            Button(action: { coordinator.toggleRecording() }) {
                HStack(spacing: Wave.spacing.s8) {
                    Image(systemName: coordinator.state == .recording ? "stop.fill" : "record.circle")
                    Text(coordinator.state == .recording ? "Stop Recording" : "Start Recording")
                    Spacer()
                    Text("⌘⇧Space")
                        .waveFont(Wave.font.micro)
                        .foregroundStyle(Wave.colors.textTertiary)
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }
            .buttonStyle(.plain)

            Divider().foregroundStyle(Wave.colors.border)

            // Rewrite level picker
            HStack(spacing: Wave.spacing.s12) {
                Text("Rewrite")
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(Wave.colors.textSecondary)
                WaveSegmentedControl(selection: Binding(
                    get: { appState.selectedRewriteLevel },
                    set: { appState.selectedRewriteLevel = $0 }
                ))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical, Wave.spacing.s10)

            // Last transcription preview
            if let last = coordinator.lastCleanedText, !last.isEmpty {
                Divider().foregroundStyle(Wave.colors.border)
                VStack(alignment: .leading, spacing: Wave.spacing.s6) {
                    HStack {
                        Text("Last transcription")
                            .waveFont(Wave.font.caption)
                            .foregroundStyle(Wave.colors.textSecondary)
                        Spacer()
                        Button(action: { copyLast(last) }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Wave.colors.textSecondary)
                        }.buttonStyle(.plain)
                    }
                    Text(preview(of: last))
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textPrimary)
                        .lineLimit(3)
                }
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }

            if let error = coordinator.lastError {
                Text(error)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.destructive)
                    .lineLimit(2)
                    .padding(.horizontal, Wave.spacing.s16)
                    .padding(.bottom, Wave.spacing.s8)
            }

            Divider().foregroundStyle(Wave.colors.border)

            // Open / Quit
            Button(action: openMainWindow) {
                HStack {
                    Image(systemName: "rectangle.stack")
                    Text("Open Wave")
                    Spacer()
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }.buttonStyle(.plain)

            Button(action: { NSApp.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Wave")
                    Spacer()
                    Text("⌘Q")
                        .waveFont(Wave.font.micro)
                        .foregroundStyle(Wave.colors.textTertiary)
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }.buttonStyle(.plain)
        }
        .frame(width: 340)
        .background(Wave.colors.surfacePrimary)
    }

    // MARK: - Helpers (copy these verbatim from the old file, unchanged behavior)
    private var statusColor: Color {
        switch coordinator.state {
        case .idle:       return Wave.colors.success
        case .recording:  return Wave.colors.destructive
        case .processing, .activating, .pasting: return Wave.colors.warning
        case .cancelling: return Wave.colors.textTertiary
        }
    }
    private var statusText: String {
        switch coordinator.state {
        case .idle:       return "Ready"
        case .recording:  return "Recording"
        case .processing: return "Processing"
        case .activating: return "Activating"
        case .pasting:    return "Pasting"
        case .cancelling: return "Cancelling"
        }
    }
    private func preview(of text: String) -> String {
        text.count > 100 ? String(text.prefix(100)) + "..." : text
    }
    private func copyLast(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let url = URL(string: "wave://main") {
            NSWorkspace.shared.open(url)
        }
        for window in NSApp.windows where window.title == "Wave" {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Ad-hoc install + visual verification in both themes**

Install via the command in Global Conventions. Open the menu bar icon. Verify in **light mode**: white background, warm gray text, blue accent on selected segment, whisper-weight dividers. Verify in **dark mode** (System Settings → Appearance → Dark): warm near-black background, off-white text, light-blue accent. The four segments (Raw / Light / Moderate / Heavy) should be clearly readable and the selection animation should feel smooth.

- [ ] **Step 4: Functional verification**

- Click Start Recording → state goes to recording, overlay appears.
- Click Stop → returns to idle.
- Click each of the 4 Rewrite segments → selection updates, persists across relaunch.
- Dictate a phrase with Raw mode → Last transcription section appears with the text.
- Click the copy icon on Last transcription → pasteboard contains the text.
- Click Open Wave → main window opens.

- [ ] **Step 5: Commit**

```bash
git add Wave/UI/MenuBar/MenuBarView.swift
git commit -m "ui: rewrite menu bar popover with Notion tokens + components"
```

---

## Phase 4 — Rewrite setup wizard

**Files:**
- Modify: `Wave/UI/SetupWizard/SetupWizardView.swift`

### Task 4.1: Rewrite SetupWizardView

- [ ] **Step 1: Rewrite the body and subviews** of `SetupWizardView.swift` to use `WaveCard.hero`, `Wave.font.*`, and `WaveButton`. The step logic (2 steps: welcome+permissions, model download) stays identical; only the visual treatment changes.

Replace the body of `SetupWizardView` with:

```swift
var body: some View {
    ZStack {
        Wave.colors.surfaceSecondary.ignoresSafeArea()

        VStack(spacing: Wave.spacing.s32) {
            // Progress dots
            HStack(spacing: Wave.spacing.s8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Wave.colors.accent : Wave.colors.border)
                        .frame(width: 32, height: 4)
                }
            }

            WaveCard(style: .hero, padding: Wave.spacing.s32) {
                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: modelAndFinishStep
                    default: EmptyView()
                    }
                }
                .frame(minWidth: 420, minHeight: 280)
            }
            .frame(maxWidth: 520)

            // Navigation
            HStack {
                if currentStep == 1 && !modelDownloaded {
                    WaveButton("Back", kind: .ghost) {
                        withAnimation(.easeOut(duration: 0.2)) { currentStep -= 1 }
                    }
                }
                Spacer()
                if currentStep == 1 {
                    if modelDownloaded {
                        WaveButton("Get Started", kind: .primary, action: saveAndFinish)
                    } else if !isDownloadingModel && modelError == nil {
                        WaveButton("Download Model", kind: .primary, action: startModelDownload)
                    }
                } else {
                    WaveButton("Continue", kind: .primary) {
                        withAnimation(.easeOut(duration: 0.2)) { currentStep += 1 }
                    }
                }
            }
            .frame(maxWidth: 520)
        }
        .padding(Wave.spacing.s48)
    }
    .frame(minWidth: 640, minHeight: 520)
}
```

- [ ] **Step 2: Rewrite `welcomeStep` and `modelAndFinishStep`** computed properties in the same file.

```swift
private var welcomeStep: some View {
    VStack(spacing: Wave.spacing.s24) {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .deepCardShadow()

        VStack(spacing: Wave.spacing.s8) {
            Text("Welcome to Wave")
                .waveFont(Wave.font.displayHero)
                .foregroundStyle(Wave.colors.textPrimary)
            Text("Turn your voice into polished text, anywhere on your Mac.")
                .waveFont(Wave.font.bodyLarge)
                .foregroundStyle(Wave.colors.textSecondary)
                .multilineTextAlignment(.center)
        }

        VStack(spacing: Wave.spacing.s8) {
            PermissionRow(
                title: "Microphone",
                description: "Required for voice recording",
                isGranted: AudioSessionManager.shared.hasMicrophonePermission,
                action: { Task { await AudioSessionManager.shared.requestMicrophonePermission() } }
            )
            PermissionRow(
                title: "Accessibility",
                description: "Required to paste text into other apps",
                isGranted: AccessibilityManager.shared.isAccessibilityEnabled,
                action: { AccessibilityManager.shared.requestAccessibilityPermission() }
            )
        }
    }
}

private var modelAndFinishStep: some View {
    VStack(spacing: Wave.spacing.s20) {
        Image(systemName: modelDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
            .font(.system(size: 56))
            .foregroundStyle(modelDownloaded ? Wave.colors.success : Wave.colors.accent)

        Text(modelDownloaded ? "You're all set!" : "Download Voice Model")
            .waveFont(Wave.font.displayLarge)
            .foregroundStyle(Wave.colors.textPrimary)

        Text(modelDownloaded
             ? "Press ⌘⇧Space anywhere to start recording. Wave will transcribe, clean up, and paste your text."
             : "Wave uses a local AI model (~150 MB) for fast, private speech recognition. It runs entirely on your Mac.")
            .waveFont(Wave.font.body)
            .foregroundStyle(Wave.colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 380)

        if isDownloadingModel {
            VStack(spacing: Wave.spacing.s12) {
                ProgressView().scaleEffect(1.2)
                Text(downloadStatus)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.textSecondary)
            }
        }

        if let error = modelError {
            VStack(spacing: Wave.spacing.s8) {
                Text(error)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.destructive)
                    .multilineTextAlignment(.center)
                WaveButton("Retry", kind: .secondary) {
                    modelError = nil
                    startModelDownload()
                }
            }
        }
    }
}
```

- [ ] **Step 3: Rewrite `PermissionRow`** (currently defined at the bottom of `SetupWizardView.swift`) to use the new components.

```swift
struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: Wave.spacing.s12) {
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodySemibold)
                    .foregroundStyle(Wave.colors.textPrimary)
                Text(description)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.textSecondary)
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Wave.colors.success)
                    .font(.system(size: 20))
            } else {
                WaveButton("Grant", kind: .primary, action: action)
            }
        }
        .padding(Wave.spacing.s12)
        .background(Wave.colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r8))
    }
}
```

- [ ] **Step 4: Build + visual + functional verification**

Build: `xcodebuild ... build 2>&1 | tail -3` → expect `** BUILD SUCCEEDED **`.

Visual: to test the wizard without nuking your real prefs, add a temporary `appState.hasCompletedSetup = false` somewhere reachable, or delete the key from UserDefaults via terminal:
```bash
defaults delete com.wave.app hasCompletedSetup
```
Relaunch Wave, walk through both steps, grant permissions (or show them already granted), click Download Model, watch progress, click Get Started. Then re-set the key:
```bash
defaults write com.wave.app hasCompletedSetup -bool true
```

- [ ] **Step 5: Commit**

```bash
git add Wave/UI/SetupWizard/SetupWizardView.swift
git commit -m "ui: rewrite setup wizard with WaveCard.hero + new tokens"
```

---

## Phase 5 — Rewrite main window shell (MainWindowView + SidebarView)

**Files:**
- Modify: `Wave/UI/MainWindow/MainWindowView.swift`
- Modify: `Wave/UI/MainWindow/SidebarView.swift`

### Task 5.1: Rewrite MainWindowView

- [ ] **Step 1: Rewrite `MainWindowView.swift`**

Replace the body with:

```swift
var body: some View {
    NavigationSplitView(columnVisibility: .constant(.all)) {
        SidebarView(appState: appState)
            .background(Wave.colors.background)
            .frame(minWidth: Wave.window.sidebarWidth)
    } detail: {
        ZStack {
            Wave.colors.surfaceSecondary.ignoresSafeArea()
            detailView
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                MicrophoneSelector()
            }
        }
    }
    .navigationSplitViewStyle(.balanced)
    .frame(minWidth: Wave.window.mainWidth, minHeight: Wave.window.mainHeight)
    .onAppear { appState.isMainWindowOpen = true }
    .onDisappear { appState.isMainWindowOpen = false }
}

@ViewBuilder
private var detailView: some View {
    switch appState.selectedSidebarItem {
    case .home:          HomeView(appState: appState, coordinator: coordinator)
    case .modes:         ModesView(appState: appState)
    case .vocabulary:    VocabularyView()
    case .snippets:      SnippetsView()
    case .configuration: ConfigurationView(appState: appState, coordinator: coordinator)
    case .sound:         SoundView(appState: appState)
    case .modelsLibrary: ModelsLibraryView(appState: appState, coordinator: coordinator)
    case .history:       HistoryView()
    }
}
```

Remove the old `RadialGradient` glow — Notion's design is restrained depth, no glow overlay.

### Task 5.2: Rewrite SidebarView

- [ ] **Step 1: Rewrite `SidebarView.swift`**

```swift
// Wave/UI/MainWindow/SidebarView.swift
import SwiftUI

struct SidebarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand header
            HStack(spacing: Wave.spacing.s8) {
                Image(systemName: "waveform")
                    .foregroundStyle(Wave.colors.accent)
                Text("Wave")
                    .waveFont(Wave.font.cardTitle)
                    .foregroundStyle(Wave.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical, Wave.spacing.s20)

            // Nav items
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(item: item, isSelected: appState.selectedSidebarItem == item) {
                        appState.selectedSidebarItem = item
                    }
                }
            }
            .padding(.horizontal, Wave.spacing.s8)

            Spacer()

            // Footer version
            Text(versionString)
                .waveFont(Wave.font.micro)
                .foregroundStyle(Wave.colors.textTertiary)
                .padding(Wave.spacing.s16)
        }
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        return "Wave v\(version)"
    }
}

private struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Wave.spacing.s12) {
                Image(systemName: item.iconName)
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textSecondary)
                    .frame(width: 16)
                Text(item.rawValue)
                    .waveFont(Wave.font.nav)
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, Wave.spacing.s12)
            .padding(.vertical, Wave.spacing.s8)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            Wave.colors.accent.opacity(0.12)
        } else if isHovering {
            Wave.colors.surfaceHover
        } else {
            Color.clear
        }
    }
}
```

- [ ] **Step 2: Build + visual verification**

Build: `xcodebuild ... build 2>&1 | tail -3` → expect `** BUILD SUCCEEDED **`.

Install and launch. Open the main window. Verify sidebar: monochrome icons, selected item shows accent color + light blue background fill, hover state works. Background alternation: sidebar is `background` (white in light / warm-near-black in dark), detail area is `surfaceSecondary` (warm white / warm dark). Toolbar microphone selector is still present.

- [ ] **Step 3: Commit**

```bash
git add Wave/UI/MainWindow/MainWindowView.swift Wave/UI/MainWindow/SidebarView.swift
git commit -m "ui: rewrite main window shell + sidebar for Notion design"
```

---

## Phase 6–13 — Per-sidebar-view rewrites

Each of these phases rewrites one view. Because the views have different levels of complexity, each task varies in size, but they share a common **rewrite checklist**:

1. Replace every `.font(.system(size:))` call with `.waveFont(Wave.font.xxx)`.
2. Replace every hardcoded `Color` with `Wave.colors.xxx`.
3. Replace every hardcoded spacing constant with `Wave.spacing.sXX`.
4. Replace every hardcoded corner radius with `Wave.radius.rXX`.
5. Wrap top-level sections in `WaveSectionHeader`.
6. Replace inline card styling with `WaveCard` or `WaveCard(style: .hero)`.
7. Replace inline list rows with `WaveListItem`.
8. Replace inline setting rows with `WaveSettingRow`.
9. Replace chips/badges with `WaveChip` / `WavePillBadge`.
10. Replace ad-hoc buttons with `WaveButton`.
11. After the task, build and verify in both light and dark mode.
12. Commit with message `ui: rewrite <ViewName> for Notion design`.

### Task 6.1: Rewrite HomeView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/Home/HomeView.swift`** following the rewrite checklist above. Key structural changes:
  - Hero stat block at top: 4 stat items side-by-side with whisper dividers between them. Numbers in `Wave.font.displayLarge`, labels in `Wave.font.caption` uppercased. No card background on the stat block itself — it sits directly on the `surfaceSecondary` page background.
  - "What's New" changelog becomes a `WaveCard(style: .hero)` with a `WaveSectionHeader("What's New")` and a vertical list of entries, each a `WaveListItem`.
  - Quick action rows (existing `QuickActionRow`) become `WaveListItem` instances inside a single `WaveCard` with whisper dividers between rows.

Pseudocode sketch:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: Wave.spacing.s32) {
        WaveSectionHeader("Home", subtitle: "Dictate anywhere on your Mac with ⌘⇧Space.")

        // Hero stats
        HStack(spacing: 0) {
            StatBlock(value: "\(weeklyStats.totalWords)", label: "Words this week")
            Divider().frame(height: 48).foregroundStyle(Wave.colors.border)
            StatBlock(value: "\(Int(weeklyStats.wpm))", label: "Words per minute")
            Divider().frame(height: 48).foregroundStyle(Wave.colors.border)
            StatBlock(value: "\(weeklyStats.uniqueApps)", label: "Apps used")
            Divider().frame(height: 48).foregroundStyle(Wave.colors.border)
            StatBlock(value: weeklyStats.timeSavedFormatted, label: "Time saved")
        }

        // What's New hero card
        WaveCard(style: .hero) {
            VStack(alignment: .leading, spacing: Wave.spacing.s16) {
                WaveSectionHeader("What's New")
                VStack(spacing: 0) {
                    ForEach(changelogEntries) { entry in
                        WaveListItem(title: entry.title, subtitle: entry.summary)
                        if entry.id != changelogEntries.last?.id {
                            Divider().foregroundStyle(Wave.colors.border)
                        }
                    }
                }
            }
        }

        // Quick actions
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s16) {
                WaveSectionHeader("Quick Actions")
                VStack(spacing: 0) {
                    ForEach(quickActions) { action in
                        WaveListItem(
                            title: action.title,
                            subtitle: action.subtitle,
                            leading: action.icon,
                            onTap: action.perform
                        ) {
                            if let shortcut = action.shortcut {
                                Text(shortcut)
                                    .waveFont(Wave.font.micro)
                                    .foregroundStyle(Wave.colors.textTertiary)
                            }
                        }
                        if action.id != quickActions.last?.id {
                            Divider().foregroundStyle(Wave.colors.border)
                        }
                    }
                }
            }
        }
    }
    .padding(Wave.spacing.s32)
}

private struct StatBlock: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s4) {
            Text(value)
                .waveFont(Wave.font.displayLarge)
                .foregroundStyle(Wave.colors.textPrimary)
            Text(label.uppercased())
                .waveFont(Wave.font.caption)
                .foregroundStyle(Wave.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Wave.spacing.s20)
    }
}
```
Preserve the existing data bindings (`weeklyStats`, `changelogEntries`, `quickActions`) — only the presentation changes. The `QuickActionRow` and `StatItem` structs at the bottom of the file can be deleted since their roles are now played by `WaveListItem` and the local `StatBlock`.

- [ ] **Step 2: Build + install + visual verification** (both themes).

- [ ] **Step 3: Commit** `git add Wave/UI/MainWindow/Home/HomeView.swift && git commit -m "ui: rewrite HomeView for Notion design"`

### Task 7.1: Rewrite ModesView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/Modes/ModesView.swift`**

```swift
// Wave/UI/MainWindow/Modes/ModesView.swift
import SwiftUI

struct ModesView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                WaveSectionHeader("Rewrite Mode", subtitle: "Choose if and how Wave cleans up your dictated text.")

                VStack(spacing: Wave.spacing.s12) {
                    ForEach(RewriteLevel.allCases, id: \.self) { level in
                        ModeCard(
                            level: level,
                            isSelected: appState.selectedRewriteLevel == level,
                            onSelect: {
                                appState.selectedRewriteLevel = level
                                appState.saveToPreferences()
                            }
                        )
                    }
                }
            }
            .padding(Wave.spacing.s32)
        }
    }
}

private struct ModeCard: View {
    let level: RewriteLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Wave.spacing.s16) {
                VStack(alignment: .leading, spacing: Wave.spacing.s6) {
                    Text(level.rawValue)
                        .waveFont(Wave.font.cardTitle)
                        .foregroundStyle(Wave.colors.textPrimary)
                    Text(level.description)
                        .waveFont(Wave.font.body)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textTertiary)
                    .font(.system(size: 20))
            }
            .padding(Wave.spacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Wave.colors.accent.opacity(0.08) : Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r12))
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(isSelected ? Wave.colors.accent : Wave.colors.border, lineWidth: isSelected ? 2 : 1)
            )
            .softCardShadow()
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Build + install + visual verification.**
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite ModesView for Notion design"`

### Task 8.1: Rewrite VocabularyView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/Vocabulary/VocabularyView.swift`** following the rewrite checklist. Key structural moves:
  - Top `WaveSectionHeader("Vocabulary", subtitle: "Words Wave should always get right.")`.
  - "Add word" form in its own `WaveCard` at the top.
  - Category filter chips (existing `FilterChip`) → replaced with `WaveChip(title:isSelected:action:)`.
  - Vocabulary entries become `WaveListItem` rows inside a single `WaveCard`, with whisper dividers between rows, a delete button as the `accessory` that only appears on hover.
  - Empty state (no words yet) → `WaveEmptyState(icon: "book", title: "No words yet", subtitle: "Add words Wave should always transcribe correctly — names, jargon, product names.")`.

Preserve all existing bindings (`@State private var entries`, `selectedCategory`, `newWord`, `newReplacement`, etc.) and all calls into `DatabaseManager`. Only presentation changes.

- [ ] **Step 2: Build + verify.**
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite VocabularyView for Notion design"`

### Task 9.1: Rewrite SnippetsView + SnippetEditorView

- [ ] **Step 1: Rewrite both files** following the rewrite checklist. Structural moves:
  - Two-pane layout (list + editor) wrapped in a single `HStack` with both panes in their own `WaveCard`.
  - Left list: single `WaveCard` containing a `WaveSectionHeader("Snippets")` + an "Add" `WaveButton.ghost` in the trailing position + `WaveListItem` rows for each snippet (title = trigger phrase, subtitle = first line of content truncated, selected row uses `accent` tint).
  - Right editor: `WaveCard` with `WaveSectionHeader("Edit Snippet")` or `WaveEmptyState` if no selection. Form fields for trigger phrase (`TextField`) and content (`TextEditor`) styled with whisper borders. Save and Delete as `WaveButton.primary` and `WaveButton.ghost`.

- [ ] **Step 2: Build + verify.** Add a snippet, edit it, delete it, verify the snippet detection still fires in `RecordingCoordinator.processRecording()` (dictate the trigger phrase in Raw mode and confirm the paste is the expansion).
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite Snippets views for Notion design"`

### Task 10.1: Rewrite ConfigurationView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/Configuration/ConfigurationView.swift`** following the checklist. Structural moves:
  - Three sections: Appearance, Keyboard Shortcuts, Application Settings.
  - Each section wrapped in a `WaveCard` with a `WaveSectionHeader` at the top.
  - Every setting row becomes a `WaveSettingRow(title:subtitle:trailing:)`.
  - Overlay style picker: 2 `WaveCard` options side-by-side with visual previews inside (keep the existing `WaveformFullPreview` / `WaveformMiniPreview` from `View+Extensions.swift` — they're out of scope as noted in the spec). Selected option gets a 2 pt `accent` border.
  - Position slider uses `WaveDottedSlider`.
  - Keyboard shortcut rows use `WaveSettingRow` with the existing `KeyboardShortcuts.Recorder(for:)` in the trailing position.
  - Launch at login uses `WaveSettingRow` with `Toggle` in the trailing position.

- [ ] **Step 2: Build + verify every setting still functions.**
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite ConfigurationView for Notion design"`

### Task 11.1: Rewrite SoundView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/Sound/SoundView.swift`** following the checklist. Structural moves:
  - Two `WaveCard` sections: "Microphone" and "Playback & Sound Effects".
  - Auto-volume and silence removal as `WaveSettingRow`s with `Toggle` trailing.
  - Playback behavior picker (Pause / Stop / Do nothing) as 3 `WaveListItem` radio-style rows inside a `WaveCard`, with a filled `accent` circle on the selected row.
  - Sound effects volume uses `WaveDottedSlider`.

- [ ] **Step 2: Build + verify every setting still functions** (toggle auto-volume, change playback behavior, adjust volume and hear chime).
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite SoundView for Notion design"`

### Task 12.1: Rewrite ModelsLibraryView + ModelCard

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/ModelsLibrary/ModelsLibraryView.swift`** following the checklist. Structural moves:
  - `WaveSectionHeader("Models Library", subtitle: "...")` at top.
  - Featured combo carousel: 3 `WaveCard(style: .hero)` cards in a horizontal `ScrollView`. Each card uses its combo tint as a soft color wash in the top half via a gradient background.
  - Language Models section: `WaveSectionHeader("Language Models")` with a `WaveButton.ghost("View all")` in the trailing position, then a grid of `ModelCard` instances.
  - Voice Models section: same treatment, only has WhisperKit inside.
  - WhisperKit status: single `WaveListItem` inside a `WaveCard` with a status pill (`WavePillBadge(tone:)`) in the trailing position.

- [ ] **Step 2: Rewrite `Wave/UI/MainWindow/ModelsLibrary/ModelCard.swift`**

```swift
import SwiftUI

struct ModelCard: View {
    let model: AIModelConfig
    let isActive: Bool
    let onSelect: () -> Void
    let onConfigure: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Wave.spacing.s12) {
                HStack(alignment: .top) {
                    WaveProviderIcon(model: model, size: 32)
                    Spacer()
                    if isActive {
                        WavePillBadge("Active", tone: .info)
                    }
                }

                VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                    Text(model.name)
                        .waveFont(Wave.font.cardTitle)
                        .foregroundStyle(Wave.colors.textPrimary)
                    Text(model.description)
                        .waveFont(Wave.font.body)
                        .foregroundStyle(Wave.colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                HStack {
                    Button("Configure", action: onConfigure)
                        .buttonStyle(.plain)
                        .waveFont(Wave.font.caption)
                        .foregroundStyle(Wave.colors.accent)
                }
            }
            .padding(Wave.spacing.s20)
            .frame(width: 240, height: 200, alignment: .topLeading)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r12))
            .whisperBorder(radius: Wave.radius.r12)
            .softCardShadow()
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(isActive ? Wave.colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 3: Build + verify model cards render, selection persists, configure sheet opens and closes.**
- [ ] **Step 4: Commit** `git commit -m "ui: rewrite ModelsLibrary + ModelCard for Notion design"`

### Task 13.1: Rewrite HistoryView

- [ ] **Step 1: Rewrite `Wave/UI/MainWindow/History/HistoryView.swift`** following the checklist. Structural moves:
  - `WaveSectionHeader("History", subtitle: "\(count) recordings")` at the top.
  - Search field as a `TextField` with a leading magnifying-glass SF Symbol, whisper border, `Wave.radius.r8`.
  - Date group headers (`Today`, `Yesterday`, date strings) as `Text` in `Wave.font.bodySemibold` with `textSecondary` color.
  - Each history entry as a `WaveListItem` inside a `WaveCard` per date group, with timestamp in `Wave.font.micro` `textTertiary` as the leading, transcript preview as the title, source app as subtitle, clicking copies to clipboard (preserve existing tap behavior).
  - Empty state: `WaveEmptyState(icon: "clock", title: "No recordings yet", subtitle: "Your dictation history will appear here.")`.

- [ ] **Step 2: Build + verify history loads, search filters, click copies.**
- [ ] **Step 3: Commit** `git commit -m "ui: rewrite HistoryView for Notion design"`

---

## Phase 14 — Polish + cleanup

**Files:**
- Modify: `Wave/UI/Theme/WaveTheme.swift` (remove legacy shim)
- Modify: `Wave/Extensions/View+Extensions.swift` (remove migrated components)
- Any view file with leftover hardcoded values surfaced during the sweep.

### Task 14.1: Remove legacy shim + migrated components

- [ ] **Step 1: Find any remaining raw `.font(.system` calls in scope**

Run: `grep -rn "\.font(\.system" Wave/UI --include="*.swift"`
Expected: ideally zero matches. Any matches are legitimate only inside Wave's own component library (e.g., the 20 pt `.font(.system(size: 20))` for a chevron icon in `ModeCard`). Flag any matches in view files outside `Wave/UI/Theme/` and convert them to `.waveFont(Wave.font.xxx)`.

- [ ] **Step 2: Find any remaining raw color literals in scope**

Run: `grep -rnE "Color\.(white|black|gray|blue|red|green|orange|purple|pink|yellow|teal|indigo|brown)" Wave/UI --include="*.swift"`
Expected: flag every match outside `Wave/UI/Theme/`. Convert to `Wave.colors.xxx`. Exception: semantic system colors used inside component definitions are OK if they already map through the adaptive helper.

- [ ] **Step 3: Remove the legacy shim**

Delete the `enum WaveTheme`, `struct CardStyle`, and `struct SectionHeaderStyle` blocks from `Wave/UI/Theme/WaveTheme.swift` — everything from the `// MARK: - Legacy shims` marker through the end of the file. Before deleting, run:

```bash
grep -rn "WaveTheme\." Wave/ --include="*.swift" | grep -v "Wave/UI/Theme/WaveTheme.swift"
```

Expected: zero matches (all references should have been migrated in phases 3–13). Any remaining matches must be fixed by converting them to `Wave.colors/spacing/radius/font.xxx` before the shim can be deleted.

- [ ] **Step 4: Remove the migrated components from `View+Extensions.swift`**

Delete the existing `EmptyStateView`, `HelpTooltipIcon`, and `DottedSlider` structs. Leave `WaveformFullPreview` and `WaveformMiniPreview` untouched (overlay-adjacent, out of scope).

Before deleting, verify no view still references the old names:
```bash
grep -rn "EmptyStateView\|HelpTooltipIcon\|DottedSlider" Wave/ --include="*.swift" | grep -v "Wave/Extensions/View+Extensions.swift"
```
Expected: zero matches.

- [ ] **Step 5: Build + thorough visual sweep**

Build: `xcodebuild ... build 2>&1 | tail -3` → `** BUILD SUCCEEDED **`.

Ad-hoc install. For each macOS appearance (Light, then Dark):
1. Click through every sidebar item in order.
2. Open the menu bar popover.
3. Trigger a recording and paste.
4. Verify no view has hardcoded-looking colors, no orphaned fonts, no oversized padding, no whisper border missing from a card.

- [ ] **Step 6: Commit**

```bash
git add Wave/UI/Theme/WaveTheme.swift Wave/Extensions/View+Extensions.swift
git commit -m "ui: remove legacy theme shim + migrated components"
```

### Task 14.2: Final smoke test (12-point verification from the spec)

- [ ] **Step 1: Build Debug + Release**

```bash
xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" build 2>&1 | tail -3
xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Release -destination 'platform=macOS' CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" build 2>&1 | tail -3
```
Both expected: `** BUILD SUCCEEDED **` with zero new warnings.

- [ ] **Step 2: Light mode sanity sweep**

Set macOS appearance to Light. Install. Click every sidebar item, open menu bar, delete `hasCompletedSetup` to re-trigger the wizard, walk through it, re-set `hasCompletedSetup`. Every view must render cleanly with no dark colors bleeding through.

- [ ] **Step 3: Dark mode sanity sweep**

Set macOS appearance to Dark. Repeat step 2.

- [ ] **Step 4: Live appearance switch**

With Wave open on the main window (Home view), switch macOS appearance. Every token should re-render instantly without relaunch.

- [ ] **Step 5: Typography spot-check**

Navigate to the setup wizard welcome (or Home). Verify `displayHero` / `displayLarge` headings look like compressed SF Pro with visible negative tracking, not default SwiftUI typography.

- [ ] **Step 6: Border + shadow consistency**

Open macOS Accessibility Inspector. Inspect each card in Home, ModelsLibrary, and Configuration. Every card's border must be 1 pt using the adaptive `border` token (10% black light / 8% white dark). Every card must have a multi-layer shadow (inspect via Quartz Debug or by eyeballing the soft gradient of depth).

- [ ] **Step 7: Functional non-regressions**

- Record in Raw mode → text pastes.
- Switch to Light mode via menu bar → dictate → verify cleanup (Phi 3.5 Mini auto-download triggers if needed).
- Add/edit/delete a snippet → verify snippet detection still fires in dictation.
- Add a vocabulary word → verify it's applied.
- Open Models Library → switch active model → dictate → verify new model loaded.
- Open History → search for a phrase → click to copy.

- [ ] **Step 8: Overlay untouched verification**

Trigger a recording. Confirm the floating overlay still shows the original magenta/cyan/blue `SiriWaveView` with its original animation — no Notion tokens leaked into the overlay.

- [ ] **Step 9: Menu bar cycle hotkey**

Press the global cycle-rewrite-level hotkey 4 times. Verify rotation: Raw → Light → Moderate → Heavy → Raw via the `WaveSegmentedControl` animation.

- [ ] **Step 10: Performance**

Open main window. Verify it appears within ~200 ms (subjective). Switch sidebar items rapidly. No dropped frames.

- [ ] **Step 11: Accessibility spot-check**

Enable VoiceOver (⌘F5). Navigate the sidebar with Tab. Every row should announce its label. Every button in the menu bar popover should be keyboard-reachable.

- [ ] **Step 12: Commit final state + tag**

```bash
git add -A
git commit -m "ui: polish pass — Notion redesign complete" --allow-empty
git tag notion-ui-v1
```

---

## Post-implementation notes

- **Warm-dark tuning.** If `#1b1a19` reads too yellow-brown in dark mode against the overlay's bright waveform, nudge to `#1c1b19` or `#1d1c1a`. This is a single-value change in `WaveTheme.swift`.
- **Shadow visibility in dark mode.** Black multi-layer shadows are subtle on dark backgrounds. If they're invisible, consider adding a subtle `whisperBorder` elevation (already there) and/or a `surfaceHover`-tinted "lift" state for cards at the expense of literal shadow fidelity.
- **Segmented control animation.** If the `matchedGeometryEffect` capsule feels laggy in the menu bar popover, raise the spring response from 0.28 to 0.35.
- **Tracking tuning.** SF Pro at 36 pt with `.tracking(-1.2)` may read too tight. Compare against the Notion reference at the same visual size and adjust by ±0.2 increments.
- **Empty state illustrations.** Notion's web uses hand-drawn character illustrations in hero sections. Out of scope for v1 — we stick with SF Symbols via `WaveEmptyState`.
