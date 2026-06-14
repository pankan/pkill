#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="pkill.app"
DMG="pkill.dmg"
VOL="pkill"
WIN_W=640
WIN_H=400
ICON=128

# Fresh app bundle.
./build.sh release >/dev/null

# Retina-aware background (.tiff with 1x + 2x reps) from the committed PNGs.
# Edit assets/bg_1x.png and assets/bg_2x.png to change the DMG background.
echo "▸ Composing background…"
TMP="$(mktemp -d)"
tiffutil -cathidpicheck assets/bg_1x.png assets/bg_2x.png -out "$TMP/background.tiff" >/dev/null 2>&1

echo "▸ Staging…"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
mkdir "$STAGE/.background"
cp "$TMP/background.tiff" "$STAGE/.background/background.tiff"

# Writable image we can decorate, then compress.
echo "▸ Creating writable image…"
RW="$TMP/rw.dmg"
hdiutil create -volname "$VOL" -srcfolder "$STAGE" -fs HFS+ \
    -format UDRW -ov "$RW" >/dev/null

DEV="$(hdiutil attach -readwrite -noverify -noautoopen "$RW" | awk '/Apple_HFS/{print $1; exit}')"
MNT="/Volumes/$VOL"
sleep 1

echo "▸ Arranging window (Finder)…"
osascript <<APPLESCRIPT || echo "  (Finder layout skipped — automation permission denied; image still builds)"
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {300, 140, 300 + $WIN_W, 140 + $WIN_H}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to $ICON
    set text size of opts to 13
    set background picture of opts to file ".background:background.tiff"
    set position of item "$APP" of container window to {160, 200}
    set position of item "Applications" of container window to {480, 200}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$DEV" >/dev/null 2>&1 || hdiutil detach "$DEV" -force >/dev/null

echo "▸ Compressing $DMG…"
rm -f "$DMG"
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null

rm -rf "$TMP" "$STAGE"
SIZE="$(du -h "$DMG" | cut -f1 | tr -d ' ')"
echo "▸ Done: $(pwd)/$DMG ($SIZE)"
echo "  open $DMG"
