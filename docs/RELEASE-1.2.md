# GlassFinder 1.2 development release

Branch: `glassfinder/v1.2`, based on the preserved v1.1 commit `a1970e6`. Neither v1.1 nor `main` is overwritten or merged. The user reports v1.1 builds/runs in Xcode; v1.2 native validation remains outstanding on this Linux host.

## Changes

Light and Dark now each store a full `AppearanceProfile`: transparency, tint RGB, gradient stops/opacities/positions/direction/intensity/thickness, background and counter visibility. General appearance chooses Automatic/Light/Dark; a separate Editing Profile selector explicitly chooses which saved profile Settings edits. Automatic selects the appropriate saved profile using the system color scheme; there is no third/shared profile. Editing a profile is independent of the current display mode so that both can be configured without changing the system appearance.

Existing `preferences.v1` data is migrated additively. The prior shared transparency is copied into both profiles once, separate old backgrounds are retained, and animation, master switch, hot key, preview limit and folder bookmarks retain their values. Future saves store independent profiles. The legacy API accessors remain for compatibility, but no appearance UI uses a shared transparency control. The default counter is off; default size is Medium; fresh preview limit is five. Existing saved preview limits are preserved.

Dark's default stroke uses muted gray stops fading toward near-dark gray at the bottom; the old bright white rim overlay is removed. Light uses its own balanced gray-blue stops. Geometry, rounded corners, pose angles, native click/double-click, menu bar, settings, login, previews, event watchers and OFF teardown remain in the existing implementation.

## Gradient editor

In Settings → Appearance, choose Edit Light Appearance or Edit Dark Appearance, then select the Keyline Gradient preview to expand the editor. Add a stop (interpolating its color/opacity from neighbors), select/remove stops, drag their handles, or enter a position from 0–100%. Use the native color picker or six-digit `#RRGGBB` field; opacity is separate. Adjust angle (0° rightward, 90° top-to-bottom), intensity and thickness, or reset only that profile's gradient.

The editor keeps 2–12 stops for predictable rendering and accessibility. Stop buttons support keyboard selection and VoiceOver adjustment; numeric fields offer an alternative to dragging. Stops keep stable IDs while reordered, out-of-range positions are clamped, and valid gradients are persisted with the profile. Gradients are drawn in each panel's local coordinate system before its existing transform, so they remain attached during hover/expansion. They affect the outline stroke only, not the glass fill. No animation loop or bitmap gradient generation is used.

No Figma screenshot was attached to this task, so the editor follows the standard preview/stop-handle/selected-stop model rather than claiming screenshot parity.

## Counts, previews and sizing

Show Item Count is saved per appearance. The label is inside the front panel near its bottom-left, and follows the hinge/scale. It shows a singular/plural immediate-child count, not a recursive total or the preview count. Counts include hidden immediate children and count subfolders/packages once; preview cards continue to skip dotfiles. A single off-main actor directory snapshot supplies both count and previews. Existing debounced filesystem notifications refresh that snapshot; appearance/gradient/counter changes do not trigger scans. Failures and master OFF clear the optional count, so unavailable folders never display a false zero.

Maximum Preview Items is global, defaults to five, and supports 1–10. It does not limit the actual count. Thumbnail cancellation and caching remain in place. Sheet depth spacing is compressed above four previews and horizontal spread is bounded, retaining the flower-like fan and original pose timing without unbounded vertical growth. Dense previews necessarily overlap; ten-item fan readability is a Mac visual QA item.

Folder Size is global: Small = 48 points, Medium = 64, Large = 96 for the stage width. Geometry, strokes, counters, transforms, hit regions, grid cells, label font/padding/gap and selection layout scale with the size. Labels stay below icons. Small counters can be compact; VoiceOver reports the count and the user can select a larger size. Company Info screenshots were not supplied in this task, so these are native-convention starting points, not a verified screenshot match. Actual 1×/2× layout and accessibility contrast require Mac QA.

## Open and build in Xcode

Download the branch ZIP:

https://github.com/Niyabrock/GlassFinder-Native-Glassmorphism-Folders-for-macOS/archive/refs/heads/glassfinder/v1.2.zip

Unzip it and open `Package.swift` in Xcode 15.4+ on macOS 14.5+. Select the GlassFinder executable and My Mac to run. For the full application project/icon build, install XcodeGen (`brew install xcodegen`), run `xcodegen generate` in the extracted folder, open `GlassFinder.xcodeproj`, choose GlassFinder → My Mac, and Run. Generated Xcode projects remain ignored. Use the bundled app to validate Launch at Login and standalone behavior.

From Terminal on a Mac:

```sh
./scripts/check.sh
./scripts/build-app.sh release arm64
open build/GlassFinder.app
./scripts/package-dmg.sh arm64
```

The expected successfully built installer path is `build/GlassFinder-1.2.0-arm64.dmg`. For a Universal 2 candidate run `./scripts/package-dmg.sh universal`; the scripts build/lipo-check arm64 and x86_64 slices, but Intel runtime compatibility is untested. Minimum deployment target remains macOS **14.5**. No compatibility claim is made for earlier releases.

Signing/notarization instructions in [the v1.1 release guide](RELEASE-1.1.md#signing-and-notarization) still apply. Metadata is now 1.2.0/build 12. The CI artifact paths are updated for 1.2.0. An unsigned/ad-hoc artifact is a development build, not a notarized public release. Installation is still: open a successfully generated DMG, drag GlassFinder.app to Applications, eject, and launch without Xcode. Do not disable macOS security protections. No `.app` or `.dmg` was generated or launched on this Linux host.

## Modified files

- `Sources/GlassFinderCore/AppearanceProfile.swift` (new): color/hex, stops, gradients, appearance profiles and layout sizes.
- `Sources/GlassFinderCore/Preferences.swift`: profile persistence, v1/v1.1 migration, active-profile selection and 1–10 limit.
- `Sources/GlassFinderCore/FileCatalog.swift`: nonrecursive snapshot count plus independent preview selection.
- `Sources/GlassFinderCore/FolderPose.swift`: bounded fan depth.
- `Sources/GlassFinder/Models/AppModel.swift`: optional count lifecycle and snapshot loading.
- `Sources/GlassFinder/Views/AppearanceSettingsView.swift`, `GradientEditor.swift` (new): explicit profile selection and native gradient UI.
- `Sources/GlassFinder/Views/SettingsView.swift`, `BackgroundSettingsView.swift`: organized General/Appearance controls and inherited background settings.
- `Sources/GlassFinder/Views/GlassFolderView.swift`: profile tint/strokes/counts, proportional dimensions and bounded fan.
- `Sources/GlassFinder/Views/FolderCard.swift`, `BrowserView.swift`: proportional hit/layout/label/grid sizes and accessible count.
- `Tests/GlassFinderCoreTests/CustomizationTests.swift` (new), `CoreTests.swift`: customization, migration, count and layout tests; updated upper-limit expectation.
- `Resources/Info.plist`, `scripts/validate-project.py`, `.github/workflows/macos.yml`: version and artifact metadata.
- `README.md`, `docs/REFERENCE.md`, `docs/VALIDATION.md`, this release guide: build instructions, design differences and validation limits.

## Evidence and Mac acceptance gate

Sixteen XCTest cases pass on Linux with Swift 6.0.3 in Swift 5 language mode. These include independent profile/gradient round-trips, Automatic profile selection, v1.1 migration, gradient interpolation/editing/bounds/hex, nonrecursive counts independent of preview limits, empty vs unavailable folders, 1–10 preview bounds and capped fan depth. Application source and the icon script pass syntax parsing; metadata, shell syntax, YAML and whitespace checks pass. Syntax parsing is not Apple-framework type checking. No v1.2 Mac UI, app-launch, DMG, signing, notarization or M1/Intel performance test has run here.

Before approving a release on a Mac:

1. Set different transparency/tint/background/count values in Light and Dark. Switch forced and Automatic appearances, then relaunch. Check each saved value and migration from a v1.1 preferences file.
2. Edit only Dark's keyline. Add, remove, drag and numerically position stops; test color, valid/invalid hex, per-stop alpha, angles, intensity, width and reset. Confirm Light is unchanged and stop IDs/values survive relaunch. Test keyboard and VoiceOver.
3. Check Dark's gray-to-darker default edge and Light's silhouette over plain/custom backgrounds at 1×/2×. Confirm stroke follows rounded geometry during hover and expansion without filling the folder.
4. Check counters for zero/one/100 children, nested folders, hidden items and unavailable drives/permissions. Modify immediate children and confirm refresh without polling; toggling the counter must not cause scans. No false zero should appear after a read failure.
5. Set limits 1, 5 and 10 on a folder with over 100 items. Confirm no more than the selected preview limit and an unchanged full count. Inspect dense fan overlap/animation bounds and rapid OFF during thumbnail generation.
6. Switch Small/Medium/Large while selected and unselected. Verify glyph/counter/keyline proportions, name gap, native selection padding, card hit testing, background dismissal and no clipping.
7. Recheck native double-click timing, drag-and-drop, keyboard selection, previews, menu bar, OFF teardown, login and relaunch. Profile edits must not interfere with these operations.
8. Build/run with Xcode, then close Xcode and install/run the bundled app independently from its DMG. Use the release guide's signing and distribution checks; measure M1 animation/idle/memory performance before claiming readiness.

Finder replacement and desktop overlays remain inactive and out of scope.
