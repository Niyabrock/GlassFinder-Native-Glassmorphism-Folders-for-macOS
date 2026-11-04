# Validation

The implementation is authored on Linux. Portable core tests can execute with a Linux Swift toolchain; parsing app sources does not type-check Apple framework APIs. A native build and runtime acceptance remain required on a Mac.

## Current cloud results

The current **Glass Folder** refinement has 24 passing XCTest cases, adding palette accuracy, coherent appearance editing, new-profile compatibility, per-folder isolation/stable UUID records, and image placement/aspect/round-trip coverage. The renamed app metadata, shell/YAML syntax, source parsing and whitespace checks pass. No native UI, PNG export, bookmark migration, app/DMG, signing or Finder/Desktop integration test was run on this Linux host. Start with [the current build and QA guide](GLASS-FOLDER.md). The paragraphs below preserve older baseline evidence.

For v1.2, sixteen XCTest cases pass, including separate appearance/gradient persistence and migration, Automatic mode selection, gradient editing/validation, direct-child counts independent of preview limits, unavailable vs empty folders, and fan/limit bounds. macOS sources are syntax-parsed, not type-checked or launched. See [the v1.2 release QA gate](RELEASE-1.2.md) for the native checks required before approval. The following paragraph records the earlier v1.1 baseline.

Swift 6.0.3 on Linux (Swift 5 language mode): eight XCTest cases executed and passed, covering real folder enumeration, missing-directory errors, preference bounds/round-trip, selection/disable precedence, reference pose/jitter parity, independent backgrounds, legacy settings migration and click-toggle behavior. Application Swift files and the icon-generation script passed syntax parsing; the portable core is type-checked by its build. Bundle metadata validation, shell syntax checks and Git whitespace checks passed. Regenerating both artwork PNGs reproduced identical SHA-256 hashes during the initial implementation. No native v1.1 application build, UI test, Finder integration test, login test or performance measurement ran here. The separate Swift Testing runner reports zero tests because this project uses XCTest; that is not the test count above. Follow the additional [v1.1 release QA gate](RELEASE-1.1.md).

## Automated Mac checks

With Apple Silicon, macOS 14.5+ and Xcode 15.4+ selected:

```sh
./scripts/check.sh
```

This checks metadata, runs core tests, builds the app, creates its bundle and verifies its development signature. Optional Xcode project validation after installing XcodeGen:

```sh
xcodegen generate
xcodebuild -project 'Glass Folder.xcodeproj' -scheme 'Glass Folder' -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
```

## Functional Mac acceptance

1. Add folders with images, a video, PDF, text document, application, subfolder and an empty folder. Verify actual thumbnails/native icons, empty status and unchanged source files/custom icons.
2. Compare closed, hover and selected graphics to the supplied reference. Only the filename should be highlighted. Hover partially opens, selection persists, and background/Escape deselects.
3. Test native slow and fast double-click intervals; Finder opens the correct URL once per double-click. Arrow keys traverse cards; Return/Space open the selection. Drag-out publishes the real folder URL with copy semantics. Dropping folders adds them without copying content.
4. Test all appearance/motion settings, persistence, VoiceOver and system Reduce Motion/Transparency. Test the menu bar with the main window closed.
5. Toggle OFF during thumbnail loads; no late result may repopulate a disabled card. Check watchers and cache are cleared. Toggle ON and verify reload. Test the optional Control–Option–Command–G shortcut, including registration conflicts.
6. Install in `/Applications`; register, approve if requested, and unregister Launch at Login. Master OFF and preference reset must not change login registration.
7. Add/remove/rename directory entries and verify debounced refresh. Test denied folders, missing drives, reconnects, sleep/wake and iCloud placeholders. Do not force a cloud download. Re-add an unresolved bookmark when needed.
8. Quit during thumbnail generation. Finder and Desktop appearance remain normal without restarting Finder.
9. Move across scaled displays and Spaces, change wallpaper, and confirm drawing stays inside the prototype. Desktop and Finder integration remain visibly inactive.

## Performance and distribution

Profile a release build on an M1 with Instruments Time Profiler, Allocations and Animation Hitches. Target 60 FPS with 10–30 chosen folders. Check idle enabled/disabled, repeated hover/refresh and very large directories. No rendering timer runs while idle; cache is capped at 32 MiB/250 images and each folder requests at most five sequential thumbnails. Enumeration sorts entries and can be expensive on huge/network directories. Frame rate, CPU, memory and scale/Spaces behavior are not measured on Linux.

Build outputs use an arm64 ad-hoc development signature. Broad distribution requires Developer ID signing, hardened runtime, notarization and login-registration testing under the release identity. Do not disable Gatekeeper or SIP as a workaround.
