#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSION_DIR="$ROOT/raycast-extension"

cd "$EXTENSION_DIR"

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required. Install Node.js first."
    exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
    echo "swift is required. Install Xcode command line tools first."
    exit 1
fi

npm install
npm run build

echo
echo "Starting Raycast dev mode. Keep this running while testing."
echo "Raycast will import RayXDR if it is not imported yet."
echo

npm run dev
