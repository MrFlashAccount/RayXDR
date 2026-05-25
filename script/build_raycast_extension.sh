#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSION_DIR="$ROOT/raycast-extension"
BIN_DIR="$EXTENSION_DIR/assets/bin"

/usr/bin/swift build -c release --package-path "$ROOT"

mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/extra-brightness" "$BIN_DIR/extra-brightness-helper"
cp "$ROOT/.build/release/rayxdr" "$BIN_DIR/rayxdr"
cp "$ROOT/.build/release/rayxdr-helper" "$BIN_DIR/rayxdr-helper"
chmod +x "$BIN_DIR/rayxdr" "$BIN_DIR/rayxdr-helper"

echo "Bundled CLI into $BIN_DIR"
