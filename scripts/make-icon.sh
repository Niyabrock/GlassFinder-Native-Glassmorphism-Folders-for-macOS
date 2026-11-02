#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo "App icon generation requires macOS." >&2; exit 1; }
mkdir -p build/AppIcon.iconset
xcrun swift scripts/make-icon.swift build/AppIcon-1024.png
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" build/AppIcon-1024.png --out "build/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" build/AppIcon-1024.png --out "build/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil --convert icns build/AppIcon.iconset --output build/AppIcon.icns
