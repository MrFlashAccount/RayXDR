#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-${RAYXDR_VERSION:-0.1.0}}"
BUILD_NUMBER="${RAYXDR_BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"
DIST_DIR="$ROOT/dist"
DMG_PATH="$DIST_DIR/RayXDR-$VERSION.dmg"
TEMP_DMG_PATH="$DIST_DIR/RayXDR-$VERSION-rw.dmg"
STAGE_DIR="$DIST_DIR/dmg-root"
BACKGROUND_SOURCE="$ROOT/assets/dmg-background.png"
VOLUME_NAME="RayXDR"

rm -rf "$DIST_DIR"
mkdir -p "$STAGE_DIR/.background"

APP_DIR="$(RAYXDR_VERSION="$VERSION" RAYXDR_BUILD_NUMBER="$BUILD_NUMBER" "$ROOT/script/build-menubar-app.sh" | tail -n 1)"
STAGED_APP_DIR="$STAGE_DIR/RayXDR.app"

/usr/bin/ditto "$APP_DIR" "$STAGED_APP_DIR"
/usr/bin/codesign --force --deep --sign - "$STAGED_APP_DIR"
/bin/cp "$BACKGROUND_SOURCE" "$STAGE_DIR/.background/dmg-background.png"

/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -fs HFS+ \
  -format UDRW \
  "$TEMP_DMG_PATH"

MOUNT_DIR=""
cleanup() {
  if [ -n "$MOUNT_DIR" ]; then
    /usr/bin/hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  /bin/rm -rf "$STAGE_DIR" "$TEMP_DMG_PATH"
}
trap cleanup EXIT

MOUNT_DIR="$(/usr/bin/hdiutil attach "$TEMP_DMG_PATH" \
  -readwrite \
  -noverify \
  -noautoopen | /usr/bin/awk -F'\t' '$0 ~ /\/Volumes\// {print $NF; exit}')"
/usr/bin/chflags hidden "$MOUNT_DIR/.background"
BACKGROUND_ALIAS="$MOUNT_DIR/.background/dmg-background.png"

/usr/bin/osascript <<OSA
set backgroundImage to POSIX file "$BACKGROUND_ALIAS" as alias

tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        if not (exists item "Applications" of container window) then
            make new alias file to (POSIX file "/Applications" as alias) at container window with properties {name:"Applications"}
        end if

        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 740, 500}

        set viewOptions to icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to backgroundImage

        set position of item "RayXDR.app" of container window to {180, 220}
        set position of item "Applications" of container window to {460, 220}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
OSA

/bin/sync
/bin/rm -rf "$MOUNT_DIR/.fseventsd" "$MOUNT_DIR/.Trashes"
/usr/bin/hdiutil detach "$MOUNT_DIR" >/dev/null

/usr/bin/hdiutil convert "$TEMP_DMG_PATH" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_PATH"

echo "$DMG_PATH"
