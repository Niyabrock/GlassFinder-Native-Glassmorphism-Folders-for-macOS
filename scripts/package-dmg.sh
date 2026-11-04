#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ "$(uname -s)" == Darwin ]] || { echo "DMG packaging requires macOS and hdiutil." >&2; exit 1; }
architecture="${1:-arm64}"
./scripts/build-app.sh release "$architecture"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
image="build/Glass-Folder-${version}-${architecture}.dmg"
staging="$(mktemp -d /tmp/GlassFinder-dmg.XXXXXX)"
trap 'rm -rf "$staging"' EXIT
ditto "build/Glass Folder.app" "$staging/Glass Folder.app"
ln -s /Applications "$staging/Applications"
hdiutil create -volname "Glass Folder $version" -srcfolder "$staging" -format UDZO -ov "$image"
hdiutil verify "$image"
if [[ "${SIGNING_IDENTITY:--}" != - ]]; then
  codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$image"
  codesign --verify "$image"
fi
if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  [[ "${SIGNING_IDENTITY:--}" != - ]] || { echo "Notarization requires a Developer ID SIGNING_IDENTITY." >&2; exit 1; }
  xcrun notarytool submit "$image" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$image"
  xcrun stapler validate "$image"
fi
echo "Packaged $image. Launch validation and signing/notarization status must be reviewed before release."
