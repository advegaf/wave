# Wave

Talk at the speed you think. Wave turns your voice into clean, well-written text in any app.

Wave is a macOS voice-to-text app that transcribes your speech locally using WhisperKit, cleans it up with Claude or GPT, and pastes the polished text wherever your cursor is. It works in every app... email, Slack, Google Docs, VS Code, iMessage, anywhere.

## How it works

1. Press **Cmd+Shift+Space** anywhere
2. Talk naturally (ramble, self-correct, use filler words)
3. Wave transcribes locally, rewrites with AI, and pastes clean text

That's it. ~1.5 second pipeline from voice to polished text.

## What makes Wave different

- **Local transcription** via WhisperKit on Apple Silicon. No audio leaves your Mac.
- **AI-powered cleanup**, not just raw dictation. Removes filler words, fixes grammar, restructures messy sentences.
- **Tone-aware by app**. Casual in Slack, professional in email. Detects which app you're in.
- **Three rewrite levels**. Light (just fix grammar), Moderate (restructure for clarity), Heavy (full professional rewrite).
- **iOS 9 Siri waveform**. Animated overlay floats above your dock while recording.
- **Personal dictionary**. Teach Wave names, jargon, and acronyms it keeps getting wrong.
- **Voice-triggered snippets**. Say "calendar" and Wave expands your scheduling link.
- **BYOK (Bring Your Own Keys)**. Uses your Anthropic or OpenAI API keys. No subscription, no middleman.

## Requirements

- macOS 14.0+ (Sonoma) or macOS 26.0+ (Tahoe) for liquid glass effects
- Apple Silicon (M1 or later) for local WhisperKit transcription
- Anthropic API key (for Claude text cleanup) or OpenAI API key (for GPT)

## Getting started

### From source

```bash
# Clone
git clone https://github.com/advegaf/wave.git
cd wave

# Generate Xcode project
brew install xcodegen
xcodegen generate

# Open in Xcode
open Wave.xcodeproj

# Set your signing team in Signing & Capabilities
# Build and run (Cmd+R)
```

### First launch

1. **Choose providers** (WhisperKit local + Claude recommended)
2. **Enter API keys** (only the ones you need)
3. **Grant permissions** (Microphone + Accessibility)
4. **Download voice model** (~150 MB, happens automatically during setup)
5. **Set preferences** (rewrite level, overlay style)

Then press **Cmd+Shift+Space** anywhere and start talking.

## Architecture

```
Cmd+Shift+Space
    |
    v
AVAudioEngine (mic capture)
    |
    v
WhisperKit (local transcription, ~300ms)
    |
    v
Claude Haiku / GPT-4o (AI cleanup, ~700ms)
    |
    v
CGEvent Cmd+V (paste into active app)
```

Built with:
- **Swift + SwiftUI** (macOS native, AppKit for system integration)
- **WhisperKit** for on-device speech-to-text
- **Anthropic Claude / OpenAI GPT** for text cleanup
- **KeyboardShortcuts** for global hotkeys
- **GRDB** for local SQLite storage
- **Core Animation** for the Siri waveform overlay

## Project structure

```
Wave/
  WaveApp.swift              # App entry point (MenuBarExtra + Window)
  AppState.swift             # Global observable state
  Core/
    Audio/                   # Mic capture, silence detection, media control
    AI/                      # Transcription + rewrite providers
    Recording/               # State machine orchestrator
    Storage/                 # SQLite database, API key storage
    System/                  # Hotkeys, clipboard, accessibility
  UI/
    Overlay/                 # Siri waveform renderer + floating panel
    MenuBar/                 # Menu bar dropdown
    MainWindow/              # Settings app (8-section sidebar)
    SetupWizard/             # First-run onboarding
    Theme/                   # Dark minimal theme
```

## Settings

Wave has a full settings app accessible from the menu bar:

- **Home** ... stats, quick actions, changelog
- **Modes** ... light / moderate / heavy rewrite levels
- **Dictionary** ... custom words organized by category (names, jargon, places)
- **Snippets** ... voice-triggered text expansions
- **Configuration** ... overlay style, keyboard shortcuts, position
- **Sound** ... microphone settings, media pause behavior, chime volume
- **Models Library** ... browse and configure voice + language models
- **History** ... searchable log of all transcriptions

## Keyboard shortcuts

| Action | Shortcut |
|--------|----------|
| Start/stop recording | Cmd+Shift+Space |
| Cancel recording | Escape |
| Push to talk | Configurable |

## Contributing

Pull requests welcome. The codebase is Swift + SwiftUI targeting macOS.

```bash
# Generate project after changes
xcodegen generate

# Build
xcodebuild -scheme Wave -configuration Debug build
```

## License

MIT
