#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "GlassFinder requires macOS 14.5+ and Xcode 15.4+ to build." >&2
  exit 1
fi
configuration="${1:-debug}"
architecture="${2:-arm64}"
case "$configuration" in debug|release) ;; *) echo "Configuration must be debug or release." >&2; exit 2 ;; esac
case "$architecture" in arm64|x86_64) architectures=("$architecture") ;; universal) architectures=(arm64 x86_64) ;; *) echo "Architecture must be arm64, x86_64 or universal." >&2; exit 2 ;; esac
export MACOSX_DEPLOYMENT_TARGET=14.5
binaries=()
binary_directory=""
for arch in "${architectures[@]}"; do
  xcrun swift build -c "$configuration" --arch "$arch" --jobs 4
  binary_directory="$(xcrun swift build -c "$configuration" --arch "$arch" --show-bin-path)"
  binaries+=("$binary_directory/GlassFinder")
done
./scripts/make-icon.sh
bundle="build/GlassFinder.app"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
if [[ "$architecture" == universal ]]; then
  lipo -create "${binaries[@]}" -output "$bundle/Contents/MacOS/GlassFinder"
else
  cp "${binaries[0]}" "$bundle/Contents/MacOS/GlassFinder"
fi
cp Resources/Info.plist "$bundle/Contents/Info.plist"
cp Sources/GlassFinder/Resources/*.png "$bundle/Contents/Resources/"
cp build/AppIcon.icns "$bundle/Contents/Resources/"
for resources in "$binary_directory"/*.bundle; do
  [[ -d "$resources" ]] || continue
  cp -R "$resources" "$bundle/Contents/Resources/"
done
# Ad-hoc by default. A Developer ID identity enables hardened runtime for distribution.
identity="${SIGNING_IDENTITY:--}"
sign_options=(--force --sign "$identity")
if [[ "$identity" != - ]]; then sign_options+=(--options runtime --timestamp); fi
codesign "${sign_options[@]}" "$bundle"
codesign --verify --strict "$bundle"
if [[ "$architecture" == universal ]]; then
  lipo -verify_arch arm64 x86_64 "$bundle/Contents/MacOS/GlassFinder"
else
  lipo -verify_arch "$architecture" "$bundle/Contents/MacOS/GlassFinder"
fi
plutil -lint "$bundle/Contents/Info.plist"
echo "Built $bundle ($architecture, configuration $configuration)"
