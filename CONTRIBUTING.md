# Contributing

```sh
brew install xcodegen   # once
xcodegen generate
xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug \
  DEVELOPMENT_TEAM=DV483F72N3 build
```

`project.yml` is the source of truth for the Xcode project, not
`Wave.xcodeproj`. A new Swift file under `Wave/` is picked up by the glob, so
`xcodegen generate` is the whole step. If you hand edit the pbxproj in a hurry,
put the same change in `project.yml` or the next generate throws it away.

Debug builds carry an Apple Development identity under team `DV483F72N3`. That
is on purpose: macOS remembers Accessibility approval per signed binary, so an
ad hoc build would ask for the permission again on every rebuild.

The version lives in two files and they have to agree:
`Wave/Info.plist` and the `info:` block in `project.yml`. Bump both.

## Images

```sh
Tools/Screenshots/make-docs-images.sh
```

Builds nothing; run a Debug build first. It launches the app once per page
under `WAVE_DEMO=curated`, photographs each window through the window server
with its own shadow, and composites the results onto a flat ground.

`WAVE_DEMO=curated` is not optional. It points the database at a throwaway
sqlite file that is deleted and reseeded on every launch, and it never calls
`saveToPreferences()`. Without it a capture photographs your real transcripts
and whatever vocabulary you have added.

Every file in `docs/images` comes out the same size on every run, because the
canvases are constants in `ArticleImages.swift` rather than the measured size of
a capture. That matters more than it sounds: macOS draws a key window a wider
drop shadow than an inactive one, a capture carries that shadow as transparent
margin, and sizing a canvas off it gave three figures that were 2176 wide on one
run and 2110 on the next.

The files are not byte identical between runs. The search field has a caret in
it and it blinks.

## What this project holds itself to

- Text that names a number has been measured. A claim in the README that cannot
  be pointed at in the code gets cut instead of softened.
- No screenshot is of the real app state. If a capture needs data, the data is a
  fixture in `Wave/Core/Demo/Demo.swift`.
- Design tokens live in `Wave/UI/Theme/WaveTheme.swift`. Views read from
  `Wave.colors`, `Wave.spacing`, `Wave.radius` and `Wave.font` rather than
  writing a hex value.
