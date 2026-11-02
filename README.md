# GlassFinder

Native SwiftUI/AppKit folder-browser prototype for macOS Sonoma 14.5+ on Apple Silicon. Choose real folders, inspect Quick Look previews, select their filenames and double-click to open directories in Finder. User files and folder icons are never changed.

**Status:** the native prototype source and packaging are implemented; native compilation and runtime checks require a Mac. The supplied React reference was inspected and adapted after the user confirmed permission. Its panel geometry, state parameters, glass gradients, timing curves and original generated artwork guide the renderer. Visual parity still requires comparison on a Mac. See [reference inspection and attribution](docs/REFERENCE.md).

**Desktop and existing Finder-window icon replacement are not implemented.** Public Finder APIs do not expose animated icon replacement. The safe alternative is the standalone browser. Settings report both integrations as inactive; see [integration analysis](docs/INTEGRATION.md).

## Build on a Mac

Requirements: macOS 14.5+, Apple Silicon, Xcode 15.4+ with full Xcode selected, and Python 3 for metadata validation. No third-party Swift dependencies or credentials.

```sh
./scripts/check.sh
open build/GlassFinder.app
```

For an optimized build, run `./scripts/build-app.sh release`. The script creates an arm64 `.app` with an ad-hoc development signature. Copy it to `/Applications` before testing Launch at Login. This is a development build, not a notarized distribution.

For Xcode's project UI, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), run `xcodegen generate`, open `GlassFinder.xcodeproj`, select the GlassFinder scheme/My Mac and Run. `project.yml` is the reproducible configuration. The package also opens directly in Xcode; use a bundled app for login registration. Generated projects and build outputs are ignored.

## Features

- Add Folders or drop real directory URLs into the window. Preview 3–5 actual entries in filename order. Unsupported types and cloud placeholders use native icons; the app never explicitly downloads iCloud items.
- Hover partially opens; selection persists after leaving. Only the filename is highlighted. Escape/empty background deselects. Arrows traverse cards; Return/Space opens in Finder. Drag-out publishes the actual URL with copy semantics. Removing a card never deletes its folder.
- Master ON/OFF in the window, settings and menu bar. OFF cancels previews, releases access, stops directory watchers, clears cache/selection and displays ordinary icons. Optional Control–Option–Command–G remains registered to turn the effect back on.
- Persistent light/dark/automatic glass, animation speed/intensity, hover, count, transparency and Reduce Motion settings. System accessibility preferences take precedence. Independent Launch at Login uses SMAppService.
- Closing the browser leaves the menu bar available. Quit tears down all resources.

## Architecture and checks

`Sources/GlassFinderCore` holds portable preferences/state and filesystem enumeration; `Tests/GlassFinderCoreTests` exercises real temporary directories and state. `Sources/GlassFinder` contains the app, native renderer, click/drag bridge, thumbnail cache, bookmarks, monitoring, hot key, menu and settings. `Resources/Info.plist`, `project.yml` and `scripts/build-app.sh` provide packaging. macOS CI runs tests and builds the app.

With Swift available on Linux, `./scripts/check.sh` runs core tests and syntax parsing only. Full macOS type-checking, UI, Quick Look, Launch at Login and M1 performance are unverified here. Follow [the validation plan](docs/VALIDATION.md); 60 FPS is a target, not a measured result.

The initial development app is not sandboxed. It reads chosen folders, persists bookmarks/preferences in UserDefaults and retains thumbnails only in memory. macOS privacy controls may deny access; use normal folder selection/system permission prompts. No Accessibility grant, Finder injection, protected system modifications or permanent custom icons are used.
