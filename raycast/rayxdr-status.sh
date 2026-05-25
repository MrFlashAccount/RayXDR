#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title RayXDR Status
# @raycast.mode compact

# Optional parameters:
# @raycast.packageName RayXDR
# @raycast.description Show current extra brightness status.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/.build/release/rayxdr"

if [[ ! -x "$BIN" ]]; then
  /usr/bin/swift build -c release --package-path "$ROOT" >/dev/null
fi

"$BIN" status
