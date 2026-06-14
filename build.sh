#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="pkill.app"
CONFIG="${1:-release}"

echo "▸ Building ($CONFIG)…"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)/pkill"

echo "▸ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/pkill"
[ -f AppIcon.icns ] && cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>pkill</string>
    <key>CFBundleDisplayName</key>     <string>pkill</string>
    <key>CFBundleIdentifier</key>      <string>com.local.pkill</string>
    <key>CFBundleVersion</key>         <string>1.0</string>
    <key>CFBundleShortVersionString</key> <string>1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>pkill</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundleIconName</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>26.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>Local build</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so the menu bar item and glass render correctly.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "▸ Done: $(pwd)/$APP"
echo "  Run with:  open $APP    (or ./build.sh && open pkill.app)"
