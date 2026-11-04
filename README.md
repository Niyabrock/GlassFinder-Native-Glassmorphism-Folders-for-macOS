# Glass Folder

Glass Folder (formerly **GlassFinder**) is a native SwiftUI/AppKit macOS folder-customization prototype. Choose real folders, apply translucent glass tints and artwork, preview their contents, and open the actual directories in Finder. The former project name, modules and repository URL remain where needed for compatibility.

The window, settings, About panel, menu bar and application bundle now use **Glass Folder**. The bundle identifier `com.glassfinder.app`, `preferences.v1`, existing bookmarks and Application Support image directory remain unchanged. Existing Light/Dark profiles, gradients and imports migrate without resetting user values.

## Current refinements

- Dark is the default for new installations. Saved Light/Dark/Automatic choices are retained. Appearance and Editing Profile share one state: selecting an editing profile switches to its explicit appearance; Automatic follows the system in both controls and the live preview.
- Seven approved Finder-inspired colors tint the glass body: Red, Orange, Yellow, Green, Blue, Purple and Gray. Choose an appearance-wide color in Settings or a persistent per-folder override in the app context menu. Finder tags are never changed.
- Drag custom artwork in its preview, or adjust horizontal/vertical position, width, height and scale numerically or with sliders. Aspect locking preserves the image's original proportions; the folder shape clips intentional cropping. Placement is saved separately for Light/Dark and can be overridden for each bookmarked folder.
- The existing multi-stop gradient editor, keylines, reflections, geometry, pose timings, count labels, native double-click, keyboard/drag handling, menu bar, OFF teardown, login and thumbnail cache are retained.
- Preview 1–10 immediate entries (default five) while independently counting all immediate children. Small/Medium/Large use 48/64/96-point stages with proportionate labels and increased gaps. These are native-convention starting points, not verified Finder screenshot matches.

## Build and launch on a Mac

Requirements: macOS 14.5+, Xcode 15.4+ with full Xcode selected, Python 3 for metadata checks. Apple Silicon is the primary target; Intel/Universal 2 runtime compatibility is unverified. There are no third-party Swift dependencies.

```sh
./scripts/check.sh
./scripts/build-app.sh release arm64
open 'build/Glass Folder.app'
```

For an Xcode application project, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), run `xcodegen generate`, open **Glass Folder.xcodeproj**, select **Glass Folder → My Mac**, and Run. The Swift package also opens directly in Xcode; its internal executable target remains `GlassFinder` for compatibility. Regenerate the project after updating so new files and renamed metadata are included. Use the packaged app to validate Launch at Login.

For an installer, run `./scripts/package-dmg.sh arm64` (or `universal` for an unverified Universal 2 candidate). The expected output is `build/Glass-Folder-1.2.0-arm64.dmg`; marketing version remains 1.2.0 and build number advances to 13 to avoid a version downgrade during the rename. Successful Mac builds produce **Glass Folder.app**, which users can drag into Applications and launch without Xcode. Signing/notarization remains required for public distribution. No `.app` or `.dmg` was built on this Linux host.

## Integration status

**Working source implementation:** the standalone app preview and a context-menu **Export Static Icon PNG** action. Export renders a closed, nonanimated 1024×1024 image without modifying folder icons or tags. The export's native renderer still requires Mac validation.

**Not implemented or tested:** automatic native Desktop/Finder styling, desktop overlays, Finder context-menu extensions and tag synchronization. Public custom-icon APIs write persistent metadata and affect Desktop/Finder together; they do not supply desktop-only hover animation. Static images cannot blur whatever wallpaper happens to be behind a native icon. No in-app mockup is presented as native integration. See [integration analysis](docs/INTEGRATION.md).

## Validation and documentation

Twenty-four portable XCTest cases pass on Linux. They cover profile migration/synchronization, exact palette values, per-folder isolation and stable IDs, image geometry/locking/round-trips, gradients, counts, limits and selection. The core is type-checked; macOS app sources and the icon generator are syntax-parsed. SwiftUI/AppKit compilation, native image rendering, app launching, installer creation and visual/performance QA remain unverified for this update.

[Refinement release guide](docs/GLASS-FOLDER.md) includes migration details, changed files, limitations, download/build instructions and a Mac QA checklist. [Design provenance](docs/REFERENCE.md) records the supplied 21st.dev source and the user's adaptation permission. The original prototype, v1.1 and v1.2 branches remain intact; their archived guides are retained for compatibility: [v1.1](docs/RELEASE-1.1.md), [v1.2](docs/RELEASE-1.2.md).

The development app is not sandboxed. It reads user-added folders; saves preferences, bookmarks and customization records in UserDefaults; keeps thumbnails in memory; and stores bounded custom PNG copies in its existing Application Support directory. Imported originals remain unchanged. The master switch stops previews/watchers, clears transient state and releases scoped access. Closing the window leaves the menu bar available; Quit tears down resources. No Accessibility grant, Finder injection, SIP change or protected-file modification is required.
