#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set RayXDR Level
# @raycast.mode compact

# Optional parameters:
# @raycast.packageName RayXDR
# @raycast.argument1 { "type": "text", "placeholder": "120 | low | medium | high | max" }
# @raycast.description Set the built-in XDR extra brightness level.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/release/rayxdr"

if [[ ! -x "$BIN" ]]; then
  /usr/bin/swift build -c release --package-path "$ROOT" >/dev/null
fi

"$BIN" set "$1"
