#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="pkill.app"
DMG="pkill.dmg"
VOL="pkill"

# Requires create-dmg:  brew install create-dmg
if ! command -v create-dmg >/dev/null 2>&1; then
    echo "Error: create-dmg not found. Install it with:  brew install create-dmg" >&2
    exit 1
fi

# Fresh app bundle.
./build.sh release >/dev/null

# create-dmg refuses to overwrite, so clear any previous image first.
rm -f "$DMG"

# PNG background; create-dmg auto-uses assets/bg@2x.png for retina.
# Edit assets/bg.png and assets/bg@2x.png to change the DMG background.
echo "==> Building ${DMG}..."
create-dmg \
    --volname "$VOL" \
    --background "assets/bg.png" \
    --window-pos 200 140 \
    --window-size 640 400 \
    --icon-size 128 \
    --icon "$APP" 160 200 \
    --app-drop-link 480 200 \
    --hide-extension "$APP" \
    --no-internet-enable \
    "$DMG" \
    "$APP"

SIZE="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo "==> Done: $(pwd)/${DMG} (${SIZE})"
echo "  open ${DMG}"
