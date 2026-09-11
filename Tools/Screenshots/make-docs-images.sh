#!/usr/bin/env bash
# Regenerates every image in docs/images.
#
# Two steps. First the captures: each page of the main window photographed
# through the window server, with its own shadow, into a scratch directory.
# Then one pass of ArticleImages.swift, which draws the ground, composites the
# captures onto it and writes the files the README embeds.
#
# Every launch carries WAVE_DEMO=curated, so no capture touches the real
# database or photographs whatever the person running this has dictated. The
# demo run uses a throwaway sqlite file that is deleted and reseeded each time,
# and it never writes preferences.
set -Eeuo pipefail
cd "$(dirname "$0")/../.."

BIN="$(xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -showBuildSettings 2>/dev/null \
    | awk '/ BUILT_PRODUCTS_DIR =/ {print $3}')/Wave.app/Contents/MacOS/Wave"
[[ -x "$BIN" ]] || { echo "build first: xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug DEVELOPMENT_TEAM=DV483F72N3 build" >&2; exit 1; }

RAW="${WAVE_RAW_DIR:-$(mktemp -d)}"
mkdir -p "$RAW" docs/images
trap 'pkill -x Wave || true' EXIT

page_shot() {               # page_shot <name> <WAVE_DEMO_PAGE value>
    local name="$1" page="$2"
    pkill -x Wave || true
    sleep 1
    env WAVE_DEMO=curated WAVE_DEMO_PAGE="$page" "$BIN" >/dev/null 2>&1 &
    # Eight rather than four: the window is opened from a task on the menu bar
    # label, so it appears a beat after the process does, and a shorter wait
    # caught either nothing or a half-laid-out window.
    sleep 8
    swift Scripts/window-shot.swift Wave "$RAW/$name.png" --shadow >/dev/null
}

page_shot home          Home
page_shot modes         Modes
page_shot vocabulary    Vocabulary
page_shot history       History
pkill -x Wave || true

# The icon, at the size the hero draws it. Copied rather than re-exported:
# this is the same file the app ships.
cp Wave/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png "$RAW/logo.png"
cp Wave/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png docs/images/logo.png

swift Tools/Screenshots/ArticleImages.swift "$RAW" docs/images

echo "docs/images:"
ls -1 docs/images
