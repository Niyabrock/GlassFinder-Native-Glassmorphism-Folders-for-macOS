#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "GlassFinder requires macOS 14.5+ and Xcode 15.4+ to build." >&2
  exit 1
fi
configuration="${1:-debug}"
case "$configuration" in debug|release) ;; *) echo "Usage: $0 [debug|release]" >&2; exit 2 ;; esac
export MACOSX_DEPLOYMENT_TARGET=14.5
xcrun swift build -c "$configuration" --arch arm64 --jobs 4
binary_directory="$(xcrun swift build -c "$configuration" --arch arm64 --show-bin-path)"
bundle="build/GlassFinder.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
cp "$binary_directory/GlassFinder" "$bundle/Contents/MacOS/GlassFinder"
cp Resources/Info.plist "$bundle/Contents/Info.plist"
cp Sources/GlassFinder/Resources/*.png "$bundle/Contents/Resources/"
for resources in "$binary_directory"/*.bundle; do
  [[ -d "$resources" ]] || continue
  cp -R "$resources" "$bundle/Contents/Resources/"
done
codesign --force --sign - "$bundle"
codesign --verify --strict "$bundle"
echo "Built $bundle (Apple Silicon, ad-hoc development signature)"
