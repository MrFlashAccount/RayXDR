#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$BUILD_DIR/RayXDR.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
VERSION="${RAYXDR_VERSION:-0.1.0}"
BUILD_NUMBER="${RAYXDR_BUILD_NUMBER:-1}"
ICON_SOURCE="$ROOT/assets/AppIcon.icns"

/usr/bin/swift build -c release --package-path "$ROOT" --product rayxdr-menubar
/usr/bin/swift build -c release --package-path "$ROOT" --product rayxdr-helper

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/rayxdr-menubar" "$MACOS_DIR/RayXDR"
cp "$BUILD_DIR/rayxdr-helper" "$MACOS_DIR/rayxdr-helper"
cp "$ICON_SOURCE" "$RESOURCES_DIR/RayXDR.icns"
chmod +x "$MACOS_DIR/RayXDR" "$MACOS_DIR/rayxdr-helper"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>RayXDR</string>
    <key>CFBundleIdentifier</key>
    <string>app.rayxdr.RayXDR</string>
    <key>CFBundleIconFile</key>
    <string>RayXDR</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>RayXDR</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

/usr/bin/plutil -replace CFBundleShortVersionString -string "$VERSION" "$CONTENTS_DIR/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
