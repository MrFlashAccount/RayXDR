#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/.build/release"
APP_DIR="$BUILD_DIR/RayXDR.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"
VERSION="${RAYXDR_VERSION:-0.1.0}"
BUILD_NUMBER="${RAYXDR_BUILD_NUMBER:-1}"
ICON_SOURCE="$ROOT/assets/AppIcon.icns"

/usr/bin/swift build -c release --package-path "$ROOT" --product rayxdr-menubar
/usr/bin/swift build -c release --package-path "$ROOT" --product rayxdr-helper

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$FRAMEWORKS_DIR"

cp "$BUILD_DIR/rayxdr-menubar" "$MACOS_DIR/RayXDR"
cp "$BUILD_DIR/rayxdr-helper" "$MACOS_DIR/rayxdr-helper"
cp "$ROOT/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICON_SOURCE" "$RESOURCES_DIR/RayXDR.icns"
/usr/bin/ditto "$BUILD_DIR/Sparkle.framework" "$FRAMEWORKS_DIR/Sparkle.framework"
chmod +x "$MACOS_DIR/RayXDR" "$MACOS_DIR/rayxdr-helper"

/usr/bin/plutil -replace CFBundleShortVersionString -string "$VERSION" "$CONTENTS_DIR/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
/usr/bin/install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_DIR/RayXDR"
/usr/bin/codesign --force --deep --sign - "$APP_DIR"
/usr/bin/codesign --verify --deep --strict "$APP_DIR"
/usr/bin/otool -L "$MACOS_DIR/RayXDR" | /usr/bin/grep '@rpath/Sparkle.framework/Versions/B/Sparkle' >/dev/null
/usr/bin/otool -l "$MACOS_DIR/RayXDR" | /usr/bin/grep '@executable_path/../Frameworks' >/dev/null

echo "$APP_DIR"
