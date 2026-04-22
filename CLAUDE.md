# Wave — project conventions for Claude Code

> Universal rules (no AI co-author trailers, no `git add -A`, no force-push without explicit auth) live in `~/.claude/CLAUDE.md`. This file only covers Wave-specific conventions.

## Commits

- Follow the existing release-commit pattern for version bumps: `Wave vX.Y.Z: <one-line summary>` with a body that groups changes by area (e.g., Animation / Onboarding / Polish / Tooling / Docs / Version).

## Build & release

- Source of truth for the Xcode project is `project.yml` (xcodegen). When adding new Swift files, prefer letting the `sources: - Wave` glob pick them up via `xcodegen generate` rather than hand-editing `Wave.xcodeproj/project.pbxproj`. If you do hand-edit pbxproj for an emergency, also reflect the change in `project.yml` so a future `xcodegen generate` doesn't regress it.
- Version lives in two places that must stay in sync: `Wave/Info.plist` (`CFBundleShortVersionString`) and `project.yml` (under the `info:` block). Bump both.
- Release artifacts (DMG) are built ad-hoc-signed: `xcodebuild ... CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=""`. The DMG is gitignored (`*.dmg`) — distribute via `gh release create vX.Y.Z dist/Wave-X.Y.Z.dmg`.
- DMG background: regenerate via `swift Scripts/generate-dmg-background.swift dist/dmg-background.png` (writes both PNG and TIFF at 144 DPI). For a new release, build the DMG by cloning the previous release's DMG (`hdiutil convert -format UDRW`) and swapping in the new `Wave.app` + new `.bg.tiff` — preserves the working `.DS_Store` window layout.

## Code style

- Design tokens live in `Wave/UI/Theme/WaveTheme.swift` under the `Wave` namespace (`Wave.colors`, `Wave.spacing`, `Wave.radius`, `Wave.font`). Read from these — never hardcode colors, spacings, or radii in views.
- Reusable view modifiers live in `Wave/UI/Theme/Modifiers/` (e.g., `PressScale`, `ImageOutline`, `SoftCardShadow`, `WhisperBorder`). Reusable components live in `Wave/UI/Theme/Components/`. Prefer extending these over duplicating press-feedback / shadow / border plumbing in call sites.
