#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Extra Brightness Status
# @raycast.mode compact

# Optional parameters:
# @raycast.packageName Extra Brightness
# @raycast.description Show current extra brightness status.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/release/extra-brightness"

if [[ ! -x "$BIN" ]]; then
  /usr/bin/swift build -c release --package-path "$ROOT" >/dev/null
fi

"$BIN" status
