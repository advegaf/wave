# Changelog

## 0.7.2

- **Overlay animation is yours to set.** Configuration has an Animation section:
  smooth, spring or linear, with a speed. It follows Reduce Motion.
- **The setup wizard opens itself** on a first launch, rather than waiting for
  you to find the menu bar icon. Permission rows update the moment you grant
  one, with no restart.
- Press feedback on everything you can click, hover backgrounds that ease in
  over 120ms instead of snapping, and 28 by 28 hit areas on the icon only
  buttons that were smaller than a finger.
- Rewrote the light, moderate and heavy prompts so the boundary between them is
  clearer.

## 0.7.1

Cleanup after the redesign.

- The window is 900 by 700 and does not resize. It was 780 by 520, which cut
  off the Snippets pane.
- The sidebar uses the real app icon rather than an SF Symbol, and the title
  bar no longer prints "Wave" a second time next to it.
- The Models Library stopped listing cloud models it can no longer reach.
- Removed the forced dark mode. The app follows the system appearance.

## 0.7.0

A rebuilt interface, and the release where Wave stopped calling anyone.

- **Everything runs locally.** WhisperKit for the speech, an MLX model for the
  rewrite, Silero through FluidAudio to hear when you stop. No API key, no
  account, no request leaving the Mac.
- **Raw is the default**, so a fresh install dictates without downloading a
  language model at all.
- **Four levels rather than three.** Raw, Light, Moderate, Heavy, cycled from a
  shortcut.
- Completion style prompts instead of chat style ones. A small local model
  handed a chat prompt answers the text instead of rewriting it.
- A light and dark theme built on warm neutrals, and a component set behind it
  so the eight pages stop drifting apart. The recording overlay is untouched.

## 0.6.x

- Clicking a card in the Models Library makes that model the active one.
- A new app icon at every size from 16px to 1024px.

## 0.5.x

**Media pause rewritten**, after three days of the wrong fix.

It now asks MediaRemote whether anything is playing and sends a pause command
to whatever is, the way Control Center does. The old version simulated the
hardware play key, which browsers ignored and which launched Apple Music when
nothing was playing at all.

## 0.4.x

Between 400 and 800ms off the pipeline.

- The dictionary, the snippets and the rewrite context load while you are still
  talking rather than after you stop.
- Resampling, RMS and the float to int16 conversion moved to Accelerate.
- Paste delays cut from 200ms to 70ms, and prompt templates read from disk once.

## 0.3.0

- Toggling recording no longer launches Apple Music. Wave checks whether media
  is playing before sending anything, and new installs default to leaving
  playback alone.
- A failed WhisperKit initialisation resets its own flag, so the fix is no
  longer a reinstall. There is a Re-download Model button for a corrupted cache.

## 0.2.0

The first release worth installing.

- Local WhisperKit transcription.
- Paste into any app through CGEvent.
- Snippets: say a phrase, get the text it stands for.
- Auto stop after two seconds of silence, measured against the peak rather than
  a fixed threshold.
- Whisper's own artifacts (`[silence]`, `[sizzling]`) filtered out.
- The waveform overlay, with an adjustable position.
