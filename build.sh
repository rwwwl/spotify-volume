#!/bin/zsh
# Builds "Spotify Volume.app" in ./build. Drag it into /Applications.
set -euo pipefail
cd "${0:A:h}"

# Set SIGN_IDENTITY in the environment to sign with a certificate; otherwise ad-hoc.
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
APP_NAME="Spotify Volume"
EXECUTABLE="SpotifyVolume"
BUNDLE_ID="com.local.spotify-volume"
VERSION="1.0"
APP="build/$APP_NAME.app"

echo "▸ Building release for arm64 and x86_64…"
# Per-triple builds (no full Xcode needed), then merged with lipo.
for arch in arm64 x86_64; do
    swift build -c release --triple "$arch-apple-macosx13.0"
done
mkdir -p build
lipo -create \
    ".build/arm64-apple-macosx/release/$EXECUTABLE" \
    ".build/x86_64-apple-macosx/release/$EXECUTABLE" \
    -output "build/$EXECUTABLE"
BIN="build/$EXECUTABLE"

echo "▸ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$APP_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Spotify Volume needs to talk to Spotify to read and change its volume.</string>
</dict>
</plist>
PLIST

if [[ -n "$SIGN_IDENTITY" ]] && security find-identity -v -p codesigning | grep -qF "$SIGN_IDENTITY"; then
    echo "▸ Code signing with: $SIGN_IDENTITY"
    SIGN_WITH="$SIGN_IDENTITY"
else
    echo "▸ No signing identity found; using ad-hoc signing"
    SIGN_WITH="-"
fi
codesign --force --options runtime --entitlements entitlements.plist --sign "$SIGN_WITH" "$APP"

echo "✓ Done: $PWD/$APP"
echo "  Drag it into /Applications, or: cp -R \"$APP\" /Applications/"
