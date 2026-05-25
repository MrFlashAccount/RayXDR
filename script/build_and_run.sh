#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "${1:-}" in
  --verify)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/rayxdr" probe
    ;;
  --on)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/rayxdr" on "${2:-150}"
    ;;
  --off|--reset)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/rayxdr" reset
    ;;
  *)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/rayxdr" probe
    ;;
esac
