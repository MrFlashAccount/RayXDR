#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APP_DIR="$("$ROOT/script/build-menubar-app.sh")"
open "$APP_DIR"

echo "Opened $APP_DIR"
