#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-${RAYXDR_VERSION:-0.1.0}}"
BUILD_NUMBER="${RAYXDR_BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"
DIST_DIR="$ROOT/dist"
DMG_PATH="$DIST_DIR/RayXDR-$VERSION.dmg"
STAGE_DIR="$DIST_DIR/dmg-root"

rm -rf "$DIST_DIR"
mkdir -p "$STAGE_DIR"

APP_DIR="$(RAYXDR_VERSION="$VERSION" RAYXDR_BUILD_NUMBER="$BUILD_NUMBER" "$ROOT/script/build-menubar-app.sh" | tail -n 1)"
STAGED_APP_DIR="$STAGE_DIR/RayXDR.app"

/usr/bin/ditto "$APP_DIR" "$STAGED_APP_DIR"
/usr/bin/codesign --force --deep --sign - "$STAGED_APP_DIR"
/usr/bin/hdiutil create \
  -volname "RayXDR" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE_DIR"

echo "$DMG_PATH"
