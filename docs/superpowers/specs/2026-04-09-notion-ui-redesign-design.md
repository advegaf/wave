# Wave UI Redesign — Notion Design Language

## Context

Wave's current UI is a functional dark-themed SwiftUI app built with a modest design system (`WaveTheme.swift`, ~68 lines) that was enough to ship but isn't distinctive. Every view uses scattered, hardcoded font sizes with no centralized type scale, and the color palette is a cold neutral gray that feels "default dark app" rather than intentional.

The user wants to rebuild Wave's visual identity using the Notion design language captured in `DESIGN.md` (installed from `npx getdesign@latest add notion`). Notion's system is characterized by: warm neutral palette with yellow-brown undertones, "whisper" 1px borders at 10% opacity, multi-layer near-invisible shadows that feel like ambient light, aggressive negative letter-spacing on display-sized typography, a four-weight type ladder (400/500/600/700), and a warm-white section alternation pattern.

The redesign translates Notion's web-oriented system into a **native SwiftUI macOS menu-bar utility** context. That means: scale down display sizes (no 64 pt headlines in a 714 pt window), adapt the light-only design into a dual light+dark theme system, and replace NotionInter with Apple's SF Pro (applying Notion's type scale in SF letterforms rather than bundling a custom font).

## Decisions Locked (from interview)

| Topic | Decision |
|---|---|
| Theme | **System-aware** — both light (literal Notion) and dark (warm-inverted Notion) |
| Depth | **Tokens + components + layouts** — true rebuild of every in-scope view |
| Surfaces | **Main window + menu bar + setup wizard** (overlay SiriWave stays untouched) |
| Font | **SF Pro** via `.system(...)` — apply Notion's type scale in SF letterforms |
| Information architecture | **Preserve exactly** — same 8 sidebar items, same order, same routing |
| Delivery | **Phased per-surface** — ~13 checkpoints, app always compilable |

## Non-goals

- **Overlay redesign.** `SiriWaveView`, `WaveShape`, `WaveData`, `OverlayWindowController` — all untouched. The magenta/cyan/blue waveform keeps its identity.
- **Navigation restructure.** No consolidating Sound into Configuration, no merging Vocabulary and Snippets, no top-tab navigation.
- **Custom font bundling.** No Inter, no NotionInter, no Info.plist font registration.
- **Backend / logic changes.** `RecordingCoordinator`, `LocalAIEngine`, `DatabaseManager`, all settings models stay exactly as-is. This is a UI-only pass.

---

## Design tokens

### Colors (dual light + dark)

Adaptive colors via `NSColor(name:, dynamicProvider:)` wrapped as SwiftUI `Color`, or via a thin `Color(light:dark:)` helper that reads `@Environment(\.colorScheme)` and picks the right variant at render time. Wave is macOS-only so `NSColor` is the idiomatic path; the dynamic-provider approach also makes appearance changes re-render instantly without manual subscribe. The Notion palette in light mode is literal; the dark mode is a **warm-inverted** variant that preserves the yellow-brown undertone instead of reverting to cold grays.

| Token | Light | Dark | Notes |
|---|---|---|---|
| `background` | `#ffffff` | `#1b1a19` | Pure white / warm near-black. Dark is warmer than old `#1A1A1A`. |
| `surfacePrimary` | `#ffffff` | `#242320` | Card background. Light = same as page. Dark = one step warmer. |
| `surfaceSecondary` | `#f6f5f4` | `#2e2c29` | Warm white / warm dark. Used for alternating sections, subtle fills. |
| `surfaceHover` | `#f0eeeb` | `#333129` | Hover state for cards and list rows. |
| `textPrimary` | `rgba(0,0,0,0.95)` | `rgba(255,255,255,0.95)` | Near-black / near-white. Never pure. |
| `textSecondary` | `#615d59` | `#a39e98` | Warm gray 500 / warm gray 300. |
| `textTertiary` | `#a39e98` | `#615d59` | Warm gray 300 / warm gray 500 (inverted pair). |
| `border` | `rgba(0,0,0,0.1)` | `rgba(255,255,255,0.08)` | Whisper borders — the entire visual division system. |
| `accent` | `#0075de` | `#62aef0` | Notion Blue / Link Light Blue. Dark variant is lighter for contrast. |
| `accentHover` | `#005bab` | `#097fe8` | Active/pressed state. |
| `badgeBlueBg` | `#f2f9ff` | `rgba(98,174,240,0.12)` | Pill badge background. |
| `badgeBlueText` | `#097fe8` | `#62aef0` | Pill badge text. |
| `success` | `#1aae39` | `#42c561` | Green. |
| `warning` | `#dd5b00` | `#ff7f30` | Orange. |
| `destructive` | `#dd0000` | `#ff5c5c` | Delete actions, error states. |

### Spacing scale (Notion 8-based, extended)

```
space2   = 2
space4   = 4
space6   = 6
space8   = 8
space12  = 12
space16  = 16
space20  = 20
space24  = 24
space32  = 32
space48  = 48
space64  = 64
space80  = 80
```

Desktop-scaled: Notion's web layouts use 80–120 pt section gutters. Wave's 714 pt window needs ~32–48 pt gutters to feel generous without wasting space. `space64` and above are reserved for Home hero-style moments; `space48` is the standard "breathing room" between major sections within a view.

### Radius scale

```
radius4  =  4  // buttons, inputs, functional elements
radius6  =  6  // small chips, menu items
radius8  =  8  // small cards, inline elements
radius12 = 12  // standard cards, feature containers (DEFAULT)
radius16 = 16  // hero cards, setup wizard panels
radiusPill = 999  // badges, status pills, segment controls
```

### Typography scale (SF Pro, desktop-adapted)

Notion's web scale (64/54/48/40/26/22/20/16/15/14/12) is too large for a 714 pt utility window. The Wave scale keeps the **ratios and tracking characteristics** but compresses sizes for desktop context. All sizes are SF Pro (`.system`).

| Role | Size | Weight | Line Height | Tracking | Usage |
|---|---|---|---|---|---|
| `displayHero` | 36 | .bold (700) | 1.00 | -1.2 | Setup wizard welcome. Rare. |
| `displayLarge` | 28 | .bold (700) | 1.05 | -0.8 | Dashboard main heading. |
| `displayMedium` | 24 | .bold (700) | 1.10 | -0.6 | Page titles (ModesView "Rewrite Level", VocabularyView "Vocabulary"). |
| `sectionHeading` | 20 | .bold (700) | 1.15 | -0.4 | Major section headings within a view. |
| `cardTitle` | 17 | .semibold (600) | 1.20 | -0.2 | Card headers, ModelCard titles, RewriteLevelCard labels. |
| `bodyLarge` | 15 | .medium (500) | 1.45 | 0 | Intro copy, card descriptions. |
| `body` | 13 | .regular (400) | 1.45 | 0 | Standard reading text (Mac default body). |
| `bodyMedium` | 13 | .medium (500) | 1.45 | 0 | Navigation labels, emphasized UI text. |
| `bodySemibold` | 13 | .semibold (600) | 1.45 | 0 | Active states, labels on selection. |
| `nav` | 13 | .semibold (600) | 1.30 | 0 | Sidebar items, menu bar rows. |
| `caption` | 11 | .medium (500) | 1.30 | 0 | Metadata, secondary labels. |
| `captionLight` | 11 | .regular (400) | 1.30 | 0 | Descriptions, subtitle text under labels. |
| `badge` | 10 | .semibold (600) | 1.30 | +0.3 | Pill badges, status tags. Positive tracking per Notion spec. |
| `micro` | 10 | .regular (400) | 1.30 | +0.2 | Timestamps, smallest metadata. |

### Shadows

SwiftUI's `.shadow()` is single-layer. Notion's signature is 4–5 layer stacks. We implement it as a reusable `ViewModifier` that applies multiple `.shadow()` calls in sequence:

```swift
struct SoftCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.04), radius: 18, y: 4)
            .shadow(color: .black.opacity(0.027), radius: 7.85, y: 2.025)
            .shadow(color: .black.opacity(0.02), radius: 2.925, y: 0.8)
            .shadow(color: .black.opacity(0.01), radius: 1.04, y: 0.175)
    }
}

struct DeepCardShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.01), radius: 3, y: 1)
            .shadow(color: .black.opacity(0.02), radius: 7, y: 3)
            .shadow(color: .black.opacity(0.02), radius: 15, y: 7)
            .shadow(color: .black.opacity(0.04), radius: 28, y: 14)
            .shadow(color: .black.opacity(0.05), radius: 52, y: 23)
    }
}
```

Two levels: `softCardShadow()` for standard cards, `deepCardShadow()` for modals / setup wizard panels / overlaid content. In dark mode, shadows remain black (they represent depth, not light).

### Whisper borders

A single reusable modifier:

```swift
extension View {
    func whisperBorder(radius: CGFloat = Wave.radius12) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Wave.colors.border, lineWidth: 1)
        )
    }
}
```

Used on every card, every section divider, every input. The `border` token is adaptive (10% black in light, 8% white in dark).

---

## Component library

All reusable components live in a new folder `Wave/UI/Theme/Components/` and each is its own small file. They replace the scattered custom views currently in `View+Extensions.swift` and inline-defined components in individual view files.

| Component | Replaces | Notes |
|---|---|---|
| `WaveButton.primary` | ad-hoc `.buttonStyle(.borderedProminent)` | Notion Blue bg, white text, 4 pt radius, 8×16 pt padding, `scale(0.96)` on press. |
| `WaveButton.secondary` | ad-hoc `.buttonStyle(.bordered)` | Translucent warm-gray bg (`rgba(0,0,0,0.05)` light, `rgba(255,255,255,0.06)` dark), 4 pt radius. |
| `WaveButton.ghost` | ad-hoc `.buttonStyle(.plain)` | Transparent, text-only, underline on hover. |
| `WavePillBadge` | no current equivalent | 999 pt radius, `badgeBlueBg` + `badgeBlueText`, 10 pt semibold, +0.3 tracking. |
| `WaveCard` | `CardStyle` ViewModifier | `surfacePrimary` bg, whisper border, 12 pt radius, soft multi-layer shadow. |
| `WaveCard.hero` | no current equivalent | 16 pt radius, deep shadow. For setup wizard and dashboard hero. |
| `WaveSectionHeader` | `SectionHeaderStyle` | 20 pt bold with -0.4 tracking; optional subtitle below at 13 pt `textSecondary`. |
| `WaveEmptyState` | `EmptyStateView` in View+Extensions | SF Symbol icon (36 pt, `textTertiary`), 17 pt semibold title, 13 pt `textSecondary` description, optional primary button. |
| `WaveChip` | inline filter chips in VocabularyView | Rounded rect, `surfaceSecondary` bg when unselected, `accent` bg when selected. |
| `WaveSettingRow` | inline rows in ConfigurationView, SoundView | Consistent title/subtitle + trailing control pattern with whisper divider between rows. |
| `WaveListItem` | inline list rows in HistoryView, Snippets, Vocabulary | Standardized hover state, whisper divider, 13 pt body + 11 pt caption layout. |
| `WaveSegmentedControl` | raw SwiftUI `Picker(.segmented)` in MenuBarView | Custom control with pill-shaped segments, smoother animation, theme-adaptive. |
| `WaveProviderIcon` | `ProviderIcon` struct in `AIModelConfig.swift` | Provider icon as a pill-style container with adaptive background tint. Moves out of `AIModelConfig.swift` into `Wave/UI/Theme/Components/`; `AIModelConfig.swift` drops its `ProviderIcon` SwiftUI view and keeps only the data-model fields. |

### Replaces from `Wave/Extensions/View+Extensions.swift`

| Existing | New |
|---|---|
| `EmptyStateView` | `WaveEmptyState` |
| `HelpTooltipIcon` | `WaveHelpTooltip` (same API, restyled) |
| `DottedSlider` | `WaveDottedSlider` (same API, restyled) |
| `WaveformFullPreview` / `WaveformMiniPreview` | **Unchanged** — they're overlay-related and overlay is out of scope. |

---

## Per-surface layout changes

The "layout rebuild" deliverable is NOT reshuffling info architecture — it's replacing ad-hoc padding/stacking with a consistent, Notion-flavored layout grammar across every view.

### Main window shell (`MainWindowView.swift`)

- `NavigationSplitView` stays but the background shifts from `.background` flat color to `surfaceSecondary` (warm white in light, warm dark in dark) — matches Notion's alternation pattern.
- Sidebar background becomes `background` (pure white / warm near-black), creating a subtle section separation between nav and content.
- Drop the current radial glow overlay (doesn't fit Notion's restrained depth).
- Toolbar microphone selector becomes a `WavePillBadge`-style button on the right.

### Sidebar (`SidebarView.swift`)

- Drop the colored SF symbol icons (blue/purple/green/orange/etc). Notion's sidebar uses single-color monochrome icons. All icons become `textSecondary` (unselected) or `accent` (selected).
- Selected state: 12 pt radius filled pill with `accent` at 12% opacity, icon and label in `accent` color.
- Label font changes from default `Label` typography to `nav` (13 pt semibold, 1.30 line height).
- Footer app version becomes 10 pt `textTertiary`.

### Home (`HomeView.swift`)

- Hero stat block at top: the current 4-item stat row gets a treatment upgrade — big numbers in `displayLarge` (28 pt bold, -0.8 tracking), labels in `caption` (11 pt medium). Each stat gets a whisper border divider between them, no card background.
- "What's New" changelog becomes a `WaveCard.hero` block below the stats.
- Quick action rows (currently `QuickActionRow`) become `WaveListItem` instances — no card wrapping each row, just whisper dividers between rows and hover states.

### Modes (`ModesView.swift`)

- Replace custom `RewriteLevelCard` with `WaveCard` + custom content. Each mode is a card with `cardTitle` (17 pt semibold) for the name, `body` (13 pt) for the description, a small selection pill (`accent` filled) on the right.
- The currently selected mode gets a 2 pt `accent` border and `surfaceHover` background.

### Vocabulary (`VocabularyView.swift`)

- Category filter chips become `WaveChip` instances.
- Vocabulary entries become `WaveListItem` rows in a single `WaveCard` container — not individual cards per entry (too much visual noise). Whisper divider between rows, hover state on each row, delete icon on hover only.
- "Add word" form becomes a `WaveCard` at the top of the list.

### Snippets (`SnippetsView.swift` + `SnippetEditorView.swift`)

- Two-pane layout stays but both panes get `WaveCard` wrappers.
- Left list uses `WaveListItem` with the trigger phrase as title and the first line of content as subtitle.
- Right editor: trigger phrase field and content text area in a single `WaveCard`, save/delete buttons as `WaveButton.primary` and `WaveButton.ghost`.

### Configuration (`ConfigurationView.swift`)

- Break the 301 lines into three distinct `WaveSectionHeader` + content blocks (Appearance, Keyboard Shortcuts, Application Settings — these already exist logically).
- Each setting row becomes a `WaveSettingRow` with consistent title/subtitle + trailing control pattern.
- Overlay style picker becomes 2 `WaveCard` options with visual previews instead of the current custom `OverlayStyleOption`.
- Position slider uses the rebuilt `WaveDottedSlider`.

### Sound (`SoundView.swift`)

- Same `WaveSettingRow` treatment.
- Volume slider becomes `WaveDottedSlider`.
- Playback behavior picker becomes 3 radio-style `WaveListItem` rows (Pause / Stop / Do nothing) inside a single `WaveCard`.

### Models Library (`ModelsLibraryView.swift`)

- Featured combo carousel: 3 cards using `WaveCard.hero`, 16 pt radius, each with its combo tint as a subtle color wash in the top half.
- Language / Voice model sections use `WaveSectionHeader` with a "View all" ghost button on the right.
- Each model card uses `WaveCard` with the provider icon as a `WavePillBadge` at top, title in `cardTitle`, description in `body`, and a status row at the bottom.
- WhisperKit status section becomes a compact `WaveListItem` inside a `WaveCard`, not a standalone block.
- `ModelDetailSheet` gets a `WaveCard.hero` treatment as a modal.

### History (`HistoryView.swift`)

- Search input becomes a styled `TextField` with whisper border and leading SF Symbol magnifying glass.
- Date group headers become `WaveSectionHeader` at 20 pt bold.
- Each history entry becomes a `WaveListItem` — monospace small font for the timestamp, `body` for the transcript preview, subtle copy icon on hover.

### Menu bar popover (`MenuBarView.swift`)

- Width stays at 340 pt (from the previous Raw-mode fix).
- Status indicator: pill badge with colored dot + text in `caption` (11 pt medium).
- Start Recording: `WaveButton.primary` full-width.
- Rewrite segmented control: custom `WaveSegmentedControl` to get better visual density for 4 segments in a narrow popover.
- Last transcription preview: `WaveCard` with `textSecondary` small text.
- Open Wave / Quit Wave: `WaveButton.ghost` rows with leading SF Symbols and trailing shortcut badges.

### Setup wizard (`SetupWizardView.swift`)

- Welcome step: centered content in a single `WaveCard.hero`. App icon, `displayHero` (36 pt bold -1.2) title, `bodyLarge` (15 pt medium) subtitle, permission rows as `WaveListItem` inside the hero card.
- Model download step: same hero card, download progress becomes a custom progress bar with `accent` fill against `surfaceSecondary` track, `displayLarge` for the completion state title.
- Progress dots at top become `accent` (completed) / `border` (pending).

---

## Files to create

All new token + component definitions live under `Wave/UI/Theme/`:

```
Wave/UI/Theme/
├── WaveTheme.swift              (rewritten — exports `Wave.colors`, `Wave.spacing`, `Wave.radius`, `Wave.font`, `Wave.shadow`)
├── Components/
│   ├── WaveButton.swift
│   ├── WavePillBadge.swift
│   ├── WaveCard.swift
│   ├── WaveSectionHeader.swift
│   ├── WaveEmptyState.swift
│   ├── WaveChip.swift
│   ├── WaveSettingRow.swift
│   ├── WaveListItem.swift
│   ├── WaveSegmentedControl.swift
│   ├── WaveDottedSlider.swift
│   └── WaveHelpTooltip.swift
└── Modifiers/
    ├── WhisperBorder.swift
    ├── SoftCardShadow.swift
    └── DeepCardShadow.swift
```

## Files to modify

Every SwiftUI view file under `Wave/UI/` that's in scope gets rewritten internally. Here's the full list from Phase 3 onward:

```
Wave/UI/MenuBar/MenuBarView.swift
Wave/UI/SetupWizard/SetupWizardView.swift
Wave/UI/MainWindow/MainWindowView.swift
Wave/UI/MainWindow/SidebarView.swift
Wave/UI/MainWindow/Home/HomeView.swift
Wave/UI/MainWindow/Modes/ModesView.swift
Wave/UI/MainWindow/Vocabulary/VocabularyView.swift
Wave/UI/MainWindow/Snippets/SnippetsView.swift
Wave/UI/MainWindow/Snippets/SnippetEditorView.swift
Wave/UI/MainWindow/Configuration/ConfigurationView.swift
Wave/UI/MainWindow/Sound/SoundView.swift
Wave/UI/MainWindow/ModelsLibrary/ModelsLibraryView.swift
Wave/UI/MainWindow/ModelsLibrary/ModelCard.swift
Wave/UI/MainWindow/History/HistoryView.swift
Wave/Core/Storage/Models/AIModelConfig.swift  (remove the inline `ProviderIcon` SwiftUI struct — moves to Wave/UI/Theme/Components/WaveProviderIcon.swift; the `AIModelConfig` data struct itself is untouched)
Wave/Extensions/View+Extensions.swift  (remove components that moved to Wave/UI/Theme/Components/)
```

## Files NOT touched

```
Wave/UI/Overlay/*                      (SiriWave, WaveShape, WaveData, OverlayWindowController — out of scope)
Wave/Core/**                           (all backend, audio, recording, AI, storage logic)
Wave/AppState.swift                    (no IA changes)
Wave/WaveApp.swift                     (no app-level changes)
```

---

## Delivery phases

Each phase is its own compilable checkpoint. After each phase, Wave still builds, launches, and functions. Commit-and-smoke-test at every boundary.

| Phase | Scope | Files touched | Smoke test |
|---|---|---|---|
| **1** | `WaveTheme.swift` rewrite: tokens (colors, spacing, radii, typography, shadows), adaptive light/dark colors, typography extensions | `WaveTheme.swift` | Build green; existing views render using the new tokens with their current layouts (will look half-migrated but functional). |
| **2** | Core reusable components in `Wave/UI/Theme/Components/` | 11 new component files | Build green; add a debug view that renders one of each component in both themes to verify they look correct. |
| **3** | Menu bar popover | `MenuBarView.swift` | Click menu bar icon; new layout renders; Rewrite segment control works; dictation still functions end-to-end; light/dark appearance follows system. |
| **4** | Setup wizard | `SetupWizardView.swift` | Delete `hasCompletedSetup` from UserDefaults, relaunch, walk through both steps, confirm WhisperKit download still works. |
| **5** | Main window shell | `MainWindowView.swift`, `SidebarView.swift` | Open main window; verify sidebar nav, background alternation, toolbar microphone selector. |
| **6** | Home | `HomeView.swift` | Navigate to Home; stats render; "What's New" card shows; quick actions clickable. |
| **7** | Modes | `ModesView.swift` | 4 mode cards render; selection cycles; mode description updates. |
| **8** | Vocabulary | `VocabularyView.swift` | Add a word; filter by category; delete a word; form validation still works. |
| **9** | Snippets | `SnippetsView.swift`, `SnippetEditorView.swift` | Add a snippet; edit it; delete it; verify `RecordingCoordinator` still detects snippets correctly (no logic change, but verify). |
| **10** | Configuration | `ConfigurationView.swift` | Every setting row functional; overlay style picker still swaps overlay; keyboard shortcut recorder still captures. |
| **11** | Sound | `SoundView.swift` | Volume slider updates chime volume; playback behavior picker changes recording behavior. |
| **12** | Models Library | `ModelsLibraryView.swift`, `ModelCard.swift` | Model cards render; selection persists; `ModelDetailSheet` opens and closes. |
| **13** | History | `HistoryView.swift` | History loads; search filters; click to copy works. |
| **14** | Polish pass | All in-scope files | Side-by-side compare: toggle light ↔ dark for every view, verify no tokens slipped through, no hardcoded colors, no layout bugs. Clean up `View+Extensions.swift` (remove migrated components). |

Each phase is a commit on a feature branch. Main is clean throughout. After phase 14, merge the branch.

---

## Verification

End-to-end smoke test after phase 14:

1. **Build clean in both Debug and Release.** `xcodebuild ... -configuration Debug build` and `... -configuration Release build` both succeed with zero new warnings.
2. **Light mode sanity.** Set macOS appearance to Light. Launch Wave. Open main window. Click every sidebar item in order. Verify every view renders cleanly with no hardcoded dark colors bleeding through. Check the menu bar popover. Run through the setup wizard (delete `hasCompletedSetup` first).
3. **Dark mode sanity.** Same as above with macOS in Dark appearance.
4. **System-aware switch.** With Wave open, change macOS appearance. Every view should re-render instantly without needing a relaunch.
5. **Typography spot-checks.** Display a `displayHero` title somewhere (setup wizard welcome) and verify it looks like aggressive Notion-tracking, not default SwiftUI. Verify no view has orphaned `.font(.system(size: 12))` calls — every font call goes through the `Wave.font.*` helpers.
6. **Whisper border consistency.** Inspect every card in every view with macOS's Accessibility Inspector. Every visible border is 1 pt using the `border` token, never hardcoded.
7. **Shadow consistency.** Every card uses `.softCardShadow()` or `.deepCardShadow()` modifiers. No inline single-layer `.shadow()` calls remain.
8. **No functional regressions.** Record a dictation in Raw mode, Light mode. Switch modes via menu bar. Add/edit/delete a snippet. Add a vocabulary word. Open Models Library and activate a different model. Open History and search for a phrase. Everything behaves identically to pre-redesign.
9. **Overlay untouched.** Trigger a recording and confirm the `SiriWaveView` still shows with its original magenta/cyan/blue colors and animation.
10. **Menu bar rewrite control.** Four segments still fit (from the prior Raw-mode fix), now using the new `WaveSegmentedControl`. Cycle hotkey still rotates Raw → Light → Moderate → Heavy → Raw.
11. **Performance.** Main window should open within ~200 ms; switching sidebar items should be instant; no dropped frames during light↔dark transition.
12. **Accessibility spot-check.** VoiceOver announces sidebar items, buttons, setting rows. Keyboard navigation works (Tab through interactive elements).

If all 12 pass, the redesign ships.

---

## Open tactical questions (decide during implementation, not planning)

- **Exact warm-dark background hex.** `#1b1a19` is a first guess. Final value determined by eyeballing it against `#f6f5f4` in the dark-mode alternation — I may land on `#1c1a17` or `#1f1d19` depending on how warm is too warm.
- **Multi-layer shadow tuning in dark mode.** Black shadows on a dark background are barely visible. May need to use elevation via subtle border lightening + `surfaceHover` tint instead of true shadows in dark mode.
- **Segmented control animation.** Swift's built-in `.segmented` style has clunky selection animation. Custom `WaveSegmentedControl` can do a sliding pill underline; needs `matchedGeometryEffect` to feel smooth.
- **Negative tracking at display sizes in SF Pro.** Notion's -2.125 px at 64 px is for Inter. SF Pro needs different numbers — start with the values in the type scale table above and iterate based on visual tests.
