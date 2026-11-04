# GlassFinder 1.1 development release

Historical guide retained for the former app name and its build outputs. For the renamed application, use [Glass Folder instructions](GLASS-FOLDER.md).

## Scope and preservation

This branch starts at the working prototype commit `acdbf24`. The user reports that prototype builds and runs in Xcode. Version 1.1 changes its presentation and dismissal behavior without replacing the app architecture, folder geometry, pose values, spring timing, filesystem previews, master switch, menu bar or login implementation. The original branch remains intact. Nothing is merged into `main` automatically.

Fresh preferences use 90% transparency and no background in either appearance. Existing saved transparency and all other v1 controls are retained by an additive decoder migration. To apply the new transparency target to an existing installation, set Glass Transparency to 0.90 or use Reset Preferences. Transparency is a tint target, not a measured whole-window optical percentage: previews, reflections, keylines and system materials contribute their own pixels. System Reduce Transparency deliberately overrides glass with an opaque accessible surface.

Folder Backgrounds offers None, Aurora/Ember presets, a dot pattern and a custom image separately for Light and Dark. Automatic follows the system color scheme; forced appearance follows its own selection. Imports are downsampled to a maximum 2048-pixel dimension and copied as PNGs to `~/Library/Application Support/GlassFinder/Backgrounds/light.png` or `dark.png`. Source files are unchanged; relaunch does not require continued access to the original. Remove / Reset deletes only that appearance's app-owned copy and selects None. Preference reset selects None while retaining stored imports for optional reselection. Missing imports fall back to plain glass and show an unavailable item in Settings.

The local AppKit event monitor observes clicks but never consumes them. Folder hits are excluded from outside dismissal; background, toolbar, other-window and focus-loss events clear selection and stale hover. The first click toggles selection; the second native click opens Finder without toggling again. macOS runtime QA is required to verify this against actual AppKit hit testing and user double-click settings.

## Build an application or installer

On a Mac with Xcode 15.4+ selected and macOS 14.5+:

```sh
./scripts/check.sh
./scripts/build-app.sh release arm64
open build/GlassFinder.app
./scripts/package-dmg.sh arm64
```

The DMG output is `build/GlassFinder-1.1.0-arm64.dmg`. It contains GlassFinder.app and an Applications shortcut. Universal 2 and Intel candidates are supported by the build scripts:

```sh
./scripts/package-dmg.sh universal
./scripts/build-app.sh release x86_64
```

Universal mode builds both architectures and uses `lipo` to combine and verify them. This is a packaging capability, **not verified Intel compatibility**. Both Intel and Apple Silicon runtime acceptance are needed before advertising Universal support. The deployment target and bundle minimum remain **macOS 14.5**; no claim is made for earlier versions. Version metadata is 1.1.0/build 11, bundle identifier remains `com.glassfinder.app`, and the generated ICNS icon is copied by both packaging paths. XcodeGen's scripts generate/copy the same icon when building in Xcode.

## Install and launch without Xcode

End users need a successfully built, tested artifact, not the source ZIP. Open the appropriate DMG, drag GlassFinder.app into Applications, eject the DMG, then open GlassFinder from Applications. Xcode is required only on the build machine. Test Launch at Login after installation. Quit an older running copy before replacing it; preferences and app-owned backgrounds are retained. No Finder restart or system modification is needed.

Unsigned/ad-hoc development downloads are not a public release and may be rejected by Gatekeeper. Public delivery must use Developer ID signing and notarization rather than asking users to disable security protections.

## Signing and notarization

The default local build is ad-hoc signed. For distribution, install a valid Developer ID Application certificate in the builder's Keychain and supply its identity name. Store notarization credentials securely with `xcrun notarytool store-credentials` and refer to the Keychain profile, never commit credentials:

```sh
export SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export NOTARY_PROFILE='GlassFinder-notary'
./scripts/package-dmg.sh universal
```

With a Developer ID, the script enables hardened runtime/timestamping, signs the app and DMG, submits the image to notarytool, then staples and validates the ticket. No certificate or notarization account is supplied in this cloud environment. Use `spctl --assess --type execute --verbose build/GlassFinder.app`, test a quarantined download on a clean Mac, and verify the mounted installer before publication. A structural DMG verification or valid signature alone is not a launch test.

## Current evidence and limitations

Eight portable XCTest cases pass on Linux, including independent background selection/round-trip, old-settings migration and click-toggle state. macOS app sources and the icon-generation Swift script pass syntax parsing. Metadata, shell syntax, YAML and whitespace checks pass. SwiftUI/AppKit type checking and visual/runtime QA for 1.1 remain unrun here. This host cannot execute `hdiutil`, `iconutil`, code signing, notarization or macOS app launching, so no `.app` or `.dmg` is claimed as successfully produced here.

The GitHub Actions workflow is configured to build development Universal artifacts on a macOS runner and upload a DMG and a permissions-preserving app ZIP. Its successful execution must be checked after push; merely committing the workflow is not build evidence. Artifacts will be on the workflow run, not automatically published as a GitHub Release. No release or merge is authorized by this update.

## Mac QA gate before approval

- Compare plain Light/Dark folders at 0.90 over different window colors: no forced artwork, no opaque default panels, readable keylines at 1× and 2×.
- Choose a different image/preset per appearance. Switch Automatic via system Light/Dark, force each mode, relaunch, remove only one background, and verify the other is unchanged. Test corrupt/unavailable images and the preview disclosure controls.
- Change transparency across its range, preserving blur/geometry/keylines. Test Reduce Transparency and Reduce Motion overrides.
- Hover/leave repeatedly, click the same folder twice slowly, transfer selection, click empty padding/scroll background/toolbar/settings/another app, and press Escape. No selection or hover should stick. Native double-click should open the correct folder once; drag-and-drop and keyboard navigation should still work.
- Exercise actual folder previews, master OFF/ON, menu bar controls, quit/relaunch, saved folders and login registration.
- Quit Xcode; copy the app from the DMG to Applications and launch it independently. Check icon/version, menu bar, custom-background reload and Launch at Login. Test on an M1 Sonoma 14.5 Mac; separately test an Intel Mac before claiming Intel support.
- Check Instruments for idle CPU, hover hitches and memory after repeated image changes. The import copies are bounded, but no M1 frame-rate or memory measurement has run here.

Finder and desktop integration remain inactive. No custom system icons, injection, protected-file changes or new permission requirements are introduced.
