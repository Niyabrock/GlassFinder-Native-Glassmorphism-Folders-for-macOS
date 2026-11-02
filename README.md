# GlassFinder

Native SwiftUI/AppKit folder-browser prototype for macOS Sonoma 14.5+ on Apple Silicon. Choose real folders, inspect Quick Look previews, select their filenames and double-click to open directories in Finder. User files and folder icons are never changed.

**Earlier v1.1 baseline:** introduced plain-glass defaults, an initial 90% transparency target, visible outer keylines, independent Light/Dark backgrounds, and selection/dismissal fixes. Existing saved settings migrate without losing their values. The original prototype remains on `glassfinder/native-prototype`, and v1.1 is preserved on `glassfinder/v1.1`. See [v1.1 installation, release and QA instructions](docs/RELEASE-1.1.md).

**Current version 1.2 development:** [glassfinder/v1.2](https://github.com/Niyabrock/GlassFinder-Native-Glassmorphism-Folders-for-macOS/tree/glassfinder/v1.2) adds full independent Light/Dark appearance profiles, a multi-stop keyline gradient editor, optional direct-child counters, 1–10 previews and Small/Medium/Large layouts. The v1.1 branch is preserved. Start with [v1.2 build, download, file list and QA instructions](docs/RELEASE-1.2.md).

**Status:** the native prototype source and packaging are implemented; native compilation and runtime checks require a Mac. The supplied React reference was inspected and adapted after the user confirmed permission. Its panel geometry, state parameters, glass gradients, timing curves and original generated artwork guide the renderer. Visual parity still requires comparison on a Mac. See [reference inspection and attribution](docs/REFERENCE.md).

**Desktop and existing Finder-window icon replacement are not implemented.** Public Finder APIs do not expose animated icon replacement. The safe alternative is the standalone browser. Settings report both integrations as inactive; see [integration analysis](docs/INTEGRATION.md).

## Build on a Mac

Requirements: macOS 14.5+, Apple Silicon, Xcode 15.4+ with full Xcode selected, and Python 3 for metadata validation. No third-party Swift dependencies or credentials.

```sh
./scripts/check.sh
open build/GlassFinder.app
```

For an optimized build, run `./scripts/build-app.sh release`. The script creates an arm64 `.app` with an ad-hoc development signature. Copy it to `/Applications` before testing Launch at Login. This is a development build, not a notarized distribution.

For a development installer run `./scripts/package-dmg.sh arm64`. Use `./scripts/package-dmg.sh universal` for an unverified Universal 2 candidate (arm64 + x86_64). Both require macOS. The scripts generate an app icon and versioned DMG; no installer was produced on this Linux host. End users can drag a successfully built app from the DMG into Applications and launch without Xcode. Public downloads require Developer ID signing/notarization; see the release guide. Intel compatibility remains untested.

For Xcode's project UI, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), run `xcodegen generate`, open `GlassFinder.xcodeproj`, select the GlassFinder scheme/My Mac and Run. `project.yml` is the reproducible configuration. The package also opens directly in Xcode; use a bundled app for login registration. Generated projects and build outputs are ignored.

## Features

- Add Folders or drop real directory URLs into the window. Preview 1–10 actual entries (default five) in filename order. Unsupported types and cloud placeholders use native icons; the app never explicitly downloads iCloud items.
- Hover partially opens; selection persists after leaving. Only the filename is highlighted. Escape/empty background deselects. Arrows traverse cards; Return/Space opens in Finder. Drag-out publishes the actual URL with copy semantics. Removing a card never deletes its folder.
- Clicking the selected folder again collapses it to hover-only state. Outside clicks and window focus loss clear selection and stale hover. Native double-click timing is retained.
- Master ON/OFF in the window, settings and menu bar. OFF cancels previews, releases access, stops directory watchers, clears cache/selection and displays ordinary icons. Optional Control–Option–Command–G remains registered to turn the effect back on.
- Persistent light/dark/automatic glass, animation speed/intensity, hover, count, transparency and Reduce Motion settings. System accessibility preferences take precedence. Independent Launch at Login uses SMAppService.
- Folder Backgrounds settings offer None, custom image, Aurora/Ember presets and a dot pattern independently for Light and Dark, with preview and per-appearance reset. Automatic follows the active system appearance. No picture or pattern is applied by default.
- Appearance profiles independently store tint, transparency, keyline stops/angle/intensity/thickness, background and item-count visibility. Select the profile to edit in Settings. Optional counters report immediate children independently of the preview limit. Small/Medium/Large proportionally scale the folder and label layout; Medium uses a 64-point stage.
- Closing the browser leaves the menu bar available. Quit tears down all resources.

## Architecture and checks

`Sources/GlassFinderCore` holds portable preferences/state and filesystem enumeration; `Tests/GlassFinderCoreTests` exercises real temporary directories and state. `Sources/GlassFinder` contains the app, native renderer, click/drag bridge, thumbnail cache, bookmarks, monitoring, hot key, menu and settings. `Resources/Info.plist`, `project.yml` and `scripts/build-app.sh` provide packaging. macOS CI runs tests and builds the app.

With Swift available on Linux, `./scripts/check.sh` runs sixteen core XCTest cases and syntax parsing only. Full v1.2 macOS type-checking, UI, Quick Look, Launch at Login and M1 performance are unverified here; the user confirmed v1.1 builds/runs in Xcode. Follow [the validation plan](docs/VALIDATION.md) and [v1.2 QA checklist](docs/RELEASE-1.2.md); 60 FPS is a target, not a measured result.

The initial development app is not sandboxed. It reads chosen folders, persists bookmarks/preferences in UserDefaults and retains thumbnails only in memory. Custom backgrounds are bounded app-owned PNG copies in Application Support; originals remain unchanged. macOS privacy controls may deny access; use normal folder selection/system permission prompts. No Accessibility grant, Finder injection, protected system modifications or permanent custom icons are used.
