#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "${1:-}" in
  --verify)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/extra-brightness" probe
    ;;
  --on)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/extra-brightness" on "${2:-150}"
    ;;
  --off|--reset)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/extra-brightness" reset
    ;;
  *)
    /usr/bin/swift build -c release --package-path "$ROOT"
    "$ROOT/.build/release/extra-brightness" probe
    ;;
esac
