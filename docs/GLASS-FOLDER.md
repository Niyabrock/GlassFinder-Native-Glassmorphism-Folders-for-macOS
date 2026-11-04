# Glass Folder — rename and refinement release

This branch, `glass-folder/refinements`, builds on `glassfinder/v1.2` commit `f9b95e7`. It implements the user's Glass Folder brief within the existing architecture. The original branches and `main` remain intact. The visible app name is Glass Folder; the existing marketing version 1.2.0 is retained and the build advances to 13 rather than downgrading the installed version during the rename.

## Rename and compatibility

Window/menu/settings/About labels, bundle display/name metadata, generated Xcode project/scheme, app/installer names and current documentation use Glass Folder. Internal Swift module/target/executable names retain `GlassFinder`/`GlassFinderCore` so imports, resource loading and older build configurations remain compatible. Most importantly, the bundle identifier is still `com.glassfinder.app`, so the UserDefaults domain stays intact. `preferences.v1` and `~/Library/Application Support/GlassFinder/Backgrounds` remain unchanged. Existing imported PNGs, transparency, gradients, saved appearance and login configuration are not deliberately reset.

New `folderRecords.v1` entries contain a stable UUID, security-scoped bookmark and customization. On first launch, old `folderBookmarks.v1` data is converted to these records, and the legacy bookmark array remains available. UUIDs are saved rather than derived from a name/path; bookmark resolution follows renames where macOS permits. Unavailable bookmark records retain their customization for reconnection/relaunch. Corrupt new records are not overwritten silently. Records without a usable bookmark cannot persist and produce a session-only warning. Actual macOS bookmark/volume/rename behavior must be tested on a Mac.

Profile decoding is additive: older profiles default to no palette preset and neutral image transforms while retaining their tint, gradient and background. New installs start in Dark; explicitly saved Automatic/Light/Dark choices remain unchanged. Removing a card removes only its app record, never its underlying folder. Per-folder overrides survive global preference reset, which retains saved folders as before.

## Coherent appearance editing

There is one appearance state, `Preferences.appearance`. Editing Profile is a computed binding to its effective Light/Dark tone. Selecting an editor segment calls `editAppearance` and chooses explicit Light or Dark. Selecting the main Light/Dark control therefore selects the corresponding editor immediately. Automatic derives both the editor and renderer from the system color scheme; choosing an opposite editor segment exits Automatic explicitly. No competing @State editor value or circular onChange loop is used. The preview is always visible and reactive. The two saved profile values remain independent.

## Folder color

`FolderTint` owns the exact approved palette: Red `#F07D71`, Orange `#F5BD67`, Yellow `#FBE772`, Green `#8FE586`, Blue `#67A3F9`, Purple `#CC88F9`, Gray `#B5B5B8`. These are project-approved approximations, not claims about Apple's internal color constants.

Settings → Appearance offers a preset per Light/Dark profile plus the existing custom tint picker and Restore Default Folder Color. The native app card's context menu offers Folder Color → Default (Use Appearance Color) or a preset. This per-folder palette override applies to both tones of that folder without mutating global profiles. It replaces the effective tint in the rear/front glass layers; it is not just an indicator dot. The existing alpha/material/highlights/geometry remain. Custom backgrounds and high transparency can make a tint more subtle; Mac visual QA is required.

These controls are inside Glass Folder. No Finder Sync extension or arbitrary native Finder context-menu replacement is installed. Finder tags are neither read as styling defaults nor overwritten.

## Image editing

Choose a Custom Image under the active appearance's background controls, then expand Image Position and Size. Drag the image within the folder preview or use sliders/numeric controls for horizontal/vertical offset, width, height and overall scale. Width/height are percentages of the image fitted to cover the original 340×272 stage; 100% is its normal fitted size. Offsets are percentages of that stage. Locking aspect ratio applies the same size multiplier to both fitted dimensions; unlocking permits intentional independent stretching. Reset restores a centered, fitted image.

The original image aspect ratio is used to compute cover fitting, not a hardcoded artwork aspect. PNG alpha is retained by the existing PNG import path. Rendering clips to the original folder path. Source images remain untouched, with app-owned copies still capped at 2048 pixels per dimension. The same canonical coordinates are scaled after placement for Small/Medium/Large, preserving alignment through layout changes. Sliders/fields offer a keyboard alternative to dragging.

Right-click a card → Customize Color and Image to override that folder's placement separately for Light/Dark. This uses the corresponding shared custom image; it does not introduce separate per-folder image imports. Use Appearance Image Placement removes only that tone's override. The persisted UUID/bookmark links both overrides to the same folder, independently from other cards. Shared-image changes intentionally affect all folders using that appearance image.

## Retained controls and layout

The existing Figma-style linear gradient editor retains multiple stops, per-stop positions/hex/color/opacity, drag/numeric adjustment, angle, overall intensity, thickness and reset. Its existing qualified `GlassFinderCore.RGBColor` conversion avoids the macOS QuickDraw type conflict. The always-visible appearance preview now shows gradient changes directly.

Default expansion limit remains five, adjustable 1–10. Counts remain nonrecursive immediate-child totals, independent of the selected previews. Existing actor enumeration, thumbnail cache/cancellation, filesystem-event debounce, menu bar, login, OFF teardown, Reduce Motion and click/dismissal behavior remain in place.

Small/Medium/Large retain 48/64/96-point stages. Label gaps increase to 5/7/10 points, scaling fonts/selection/card layout consistently. The referenced Finder screenshots were not attached, so exact native Finder proportions are not claimed. Long filenames, selected labels and 1×/2× screens require Mac inspection.

## Supported integration boundary

[NSWorkspace.setIcon](https://developer.apple.com/documentation/appkit/nsworkspace/seticon(_:forfile:options:)) can assign a static custom icon, which writes persistent folder icon metadata. It does not create a live render surface, and the icon normally affects Finder and Desktop together. A production opt-in implementation would need consent, lossless backup/restore, crash recovery, external-icon-change handling, writable folder access and reconciliation when the master switch turns OFF. None of that is claimed as implemented here.

The implemented safe alternative is Export Static Icon PNG in a card's app context menu. `StaticIconExporter` freezes the effective color/image/gradient into a closed 1024×1024 PNG; it includes no hover, expansion, file previews or volatile count. It saves only to the user-chosen destination. It does not apply the PNG, modify xattrs/tags or change native folders. Users can assess a successfully rendered export for manual icon use, but automatic application/restore remains future work. Static icon alpha cannot reproduce live wallpaper backdrop blur.

Finder Sync supports badges/menus/status, not arbitrary animated replacement icons. Desktop overlays additionally need robust URL/frame mapping, z-order, Spaces/scaling and hit testing. No overlays, injection, system modifications or extra Accessibility prompts are introduced. Animations remain in the standalone app preview, never in native Finder. The app preview is not called a desktop integration. See [integration analysis](INTEGRATION.md).

## Build, install and download

Use a Mac with macOS 14.5+ and Xcode 15.4+. After extracting the branch source ZIP:

```sh
xcodegen generate
open 'Glass Folder.xcodeproj'
```

Select the **Glass Folder** scheme and **My Mac**, then Run. XcodeGen can be installed with `brew install xcodegen`. The Swift package still exposes an internal `GlassFinder` executable for compatibility. Regenerate the project instead of opening an old generated project that lacks the new source files.

For packaged development output:

```sh
./scripts/check.sh
./scripts/build-app.sh release arm64
open 'build/Glass Folder.app'
./scripts/package-dmg.sh arm64
```

The expected output is `build/Glass-Folder-1.2.0-arm64.dmg`. Use `universal` for an unverified Intel/Apple Silicon candidate. Public distribution requires Developer ID/hardened-runtime signing and notarization; the existing `SIGNING_IDENTITY` and Keychain `NOTARY_PROFILE` paths in the packaging script are retained. No signing credentials or Mac build host are supplied here. Install a successfully built app in Applications, quit the old copy, and validate login registration under the new app path. Do not remove the old app or user preferences automatically.

Source branch: https://github.com/Niyabrock/GlassFinder-Native-Glassmorphism-Folders-for-macOS/tree/glass-folder/refinements

ZIP: https://github.com/Niyabrock/GlassFinder-Native-Glassmorphism-Folders-for-macOS/archive/refs/heads/glass-folder/refinements.zip

## Changed implementation areas

- `FolderCustomization.swift` (new): palette, normalized image geometry, per-folder overrides and saved identity records.
- `AppearanceProfile.swift`, `Preferences.swift`: additive profile migration, Dark default, coherent appearance selection and proportional label gaps.
- `AppModel.swift`: bookmark-record migration, retained unresolved records, folder override actions and static-export save action.
- `AppearanceSettingsView.swift`, `BackgroundSettingsView.swift`: synchronized controls, palette/reset, always-visible preview and image editor.
- `FolderColorPicker.swift`, `ImagePlacementEditor.swift`, `FolderCustomizationView.swift` (new): preset UI, drag/numeric sizing and per-folder editing sheet.
- `GlassFolderView.swift`, `FolderCard.swift`, `BrowserView.swift`: effective tints/transforms, card menus, customization sheet and visible rename.
- `GlassFinderApp.swift`, `SettingsView.swift`, `IntegrationStatus.swift`: visible app/About/menu/settings naming and honest integration statuses.
- `StaticIconExporter.swift` (new): frozen PNG rendering without native folder mutation.
- `BackgroundStore.swift`: explicitly retained legacy import location.
- `Info.plist`, `Package.swift`, `project.yml`, build/DMG/validation scripts and macOS CI: display/project/bundle/artifact rename with stable IDs/modules.
- `RefinementTests.swift` (new), `CustomizationTests.swift`: migration, synchronization, palette, identity, isolation and image geometry tests.
- README and current/historical documentation: new build names, compatibility and QA evidence.

## Validation and required Mac QA

Twenty-four XCTest cases pass on Linux, including the eight new palette/sync/migration/override/image tests. The portable core is type-checked, and all macOS source plus the icon script passes syntax parsing. Metadata/shell/YAML/whitespace checks pass. These checks do not establish macOS framework compilation, bookmark recovery, SwiftUI hit testing, PNG rendering, alpha quality, installer creation, login migration or visual/performance readiness. No `.app` or `.dmg` was produced on this Linux host, and no Finder/Desktop integration was tested or enabled.

Before approving this update on a Mac:

1. Install over an existing app without deleting its preferences/imports. Check saved gradients/backgrounds/Automatic choice, scoped folders, stable per-folder overrides and login behavior. Rename a bookmarked folder, relaunch, and verify its custom settings follow; unplug/reconnect a drive and verify unresolved records are retained.
2. Switch each Editing Profile and main Appearance control repeatedly. Automatic must follow system Light/Dark in both controls and preview, without overwriting either profile. Check independent transparency/gradient/background persistence after relaunch.
3. Apply all seven presets globally and on one card. Confirm the body is tinted yet translucent. Restore Default and confirm inheritance, custom RGB picking and folder isolation. Confirm Finder tags/xattrs remain unchanged.
4. Import wide/tall PNGs with alpha. Drag, type offsets/dimensions, scale, toggle aspect lock, crop and reset; resize the folder and relaunch. Verify both shared and per-folder transforms, image fidelity and clipping. Check keyboard controls and long settings layout.
5. Retest all gradient stop operations, preview limits 1/5/10, counts for empty/large/unavailable folders, size/label layouts, double-click/drag/keyboard, OFF and Quit. No late thumbnail work should appear after OFF.
6. Export a static PNG. Verify 1024×1024 dimensions, alpha, closed pose, correct effective tint/placement/gradient, no folder name/count/animation, and no native icon/tag changes. Export appearance may differ from a live material over wallpaper; it is not native integration.
7. Build/run outside Xcode from the renamed bundle/DMG. Validate icon, About/version, menu bar, signing/notarization and both Apple Silicon/Intel targets before claiming distribution compatibility. Measure hover performance and idle CPU/memory with Instruments.
