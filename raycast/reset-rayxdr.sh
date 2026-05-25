#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Reset RayXDR
# @raycast.mode compact

# Optional parameters:
# @raycast.packageName RayXDR
# @raycast.description Restore normal brightness mode.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/release/rayxdr"

if [[ ! -x "$BIN" ]]; then
  /usr/bin/swift build -c release --package-path "$ROOT" >/dev/null
fi

"$BIN" reset
