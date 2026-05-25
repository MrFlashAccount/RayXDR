#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXTENSION_DIR="$ROOT/raycast-extension"
BIN_DIR="$EXTENSION_DIR/assets/bin"

/usr/bin/swift build -c release --package-path "$ROOT"

mkdir -p "$BIN_DIR"
cp "$ROOT/.build/release/extra-brightness" "$BIN_DIR/extra-brightness"
cp "$ROOT/.build/release/extra-brightness-helper" "$BIN_DIR/extra-brightness-helper"
chmod +x "$BIN_DIR/extra-brightness" "$BIN_DIR/extra-brightness-helper"

echo "Bundled CLI into $BIN_DIR"
