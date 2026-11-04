# Open Glass Folder in Xcode

This source download contains the Glass Folder refinement from `4bbe336`, plus the gradient-color precision and multi-window selection fixes from the Debug review. It includes the source, images, tests and project-generation configuration. It is not a compiled Mac application.

Requirements: a Mac running macOS 14.5 or later and Xcode 15.4 or later.

## Open immediately without extra tools

1. Extract the entire ZIP. Keep its folders together.
2. Open Xcode, choose File → Open, and select **Package.swift** in the extracted folder.
3. Select the **GlassFinder** executable scheme and **My Mac** as the destination. This internal scheme name is retained for compatibility; the app window is named **Glass Folder**.
4. Choose Product → Run, or press Command-R.
5. Add a real folder to test previews, then use Settings to test Light/Dark, colors, image positioning and gradients.

Do not select the GlassFinderCore library scheme when trying to run the app. Swift package launch mode is for development; bundle metadata, application icon and Launch at Login should be tested with the generated application project below.

## Generate the full application project

If you already have XcodeGen, open Terminal in the extracted folder and run:

```sh
xcodegen generate
open 'Glass Folder.xcodeproj'
```

Otherwise install XcodeGen using `brew install xcodegen` if you use Homebrew, or follow the official XcodeGen installation instructions. This is optional for opening the Swift package above.

In the generated project, select the **Glass Folder** scheme and **My Mac**. Choose Product → Build (Command-B), then Product → Run (Command-R). If your local Debug signing configuration requests a team, choose your development team in Signing & Capabilities. No App Store, notarization or release configuration is required for this development task.

Run existing tests from Terminal with `swift test --configuration debug`, or use Product → Test in the generated Glass Folder scheme.

## Validation limits

The clean portable-core Debug build and all 24 existing tests passed on Linux. macOS source syntax and project metadata were checked. A full Xcode/SwiftUI/AppKit build and native interaction tests could not run on that host and remain unverified. In particular, check gradient stop selection without unintended color changes, two-window folder selection, appearance synchronization, custom images, previews, animations and saved settings on your Mac.

The display rename retains `com.glassfinder.app`, existing preference keys and the legacy Application Support image directory. No release packaging changes or additional features were introduced by the Debug review.
