# Reference inspection

The original 21st.dev page returned HTTP 403 through the managed proxy on 2026-11-02. The user subsequently supplied the original React/TypeScript component as a pasted attachment. That source has now been inspected; its wrapper instructions for React/shadcn are not requirements for this native Swift project.

## Observed visual contract

- The stage is 340 × 272 units, with 54 units of headroom, scaled uniformly to the chosen width.
- Separate rear and front paths have asymmetrical raised tabs and 22-unit rounded corners. The front begins 74 units below the back's top and is 198 units tall.
- Sheets are 272 × 184, based at (34, 96), below the frosted front and above the artwork/back panel.
- Closed: hinge 0°, lift 42, spread 0, fan 0°, depth spacing 15.
- Hover: hinge −11°, lift −34, spread 8, fan 1.4°, depth spacing 10.
- Open: hinge −24°, lift −96, spread 40, fan 5°, depth spacing 30.
- Front perspective is 760 units, bottom-center hinge. Front timing is 0.8 seconds with a cubic-bezier spring (0.34, 1.36, 0.5, 1). Sheets use 0.75 seconds with 40 ms depth staggering. Pointer parallax uses a 1400-unit perspective and ±3°/4° rotations.
- Glass uses a 22-unit backdrop blur and 1.5 saturation; the light tint fades from 16% white to 93% off-white. Smoked glass fades from 18% near-black to 94% near-black. A radial highlight and 2.4-unit gradient rim provide reflections.
- Artwork is generated with seeded domain-warped noise and shared caching. The plain `art="none"` variation is also provided.

The requested native adaptation differs intentionally: actual filesystem thumbnails instead of sample/generated file sheets, filenames below the graphic, no plus/action key, 3–5 preview items instead of a maximum of four, native double-click-to-Finder, and a master teardown switch. The original artwork generator is optional and must not be replaced with unrelated invented artwork.

## Permission and adaptation

The supplied source contains no license text or notice. The user explicitly confirmed “I have permission” in response to the adaptation-permission question on 2026-11-02. Adaptation proceeds on that confirmation; this repository does not assert that the upstream component is MIT-licensed or grant broader upstream rights.

`Reference/ArtGenerator.ts` retains the supplied artwork algorithm and presets with attribution to kedhareswer. `scripts/generate-art.mjs` uses Node's built-in TypeScript stripping and a PNG encoder to generate the original aurora (seed 3) and ember (seed 11) artwork without npm dependencies. Generated assets are committed and loaded once; the app does not continuously synthesize noise. Run `node scripts/generate-art.mjs` with Node 22.13+ to regenerate.

`PanelPath` maps the two original SVG paths into native cubic paths (22-unit quarter circles represented by their standard cubic approximation). `FolderPose` uses the exact measured state parameters and the original stable hash/random jitter. Native rendering uses matching timing curves, front tint stops, saturation/blur, reflections and a bottom hinge. Actual thumbnails replace demo sheets. The frosted front explicitly samples a duplicate of the rear/sheet layers to avoid assuming SwiftUI material samples sibling views.

This is a native adaptation, not the React component running inside a web view. Apple rasterization, perspective and blur can differ from browser CSS. Visual parity has not been measured on macOS; the supplied source is the definitive reference for the Mac acceptance comparison. No pixel-perfect or 60 FPS claim is made.

## Intentional v1.1 refinements

At the user's request, backgrounds are now opt-in rather than always showing the original artwork. New installations start with no background in either tone and a 90% transparency target. The original Aurora/Ember assets remain available as explicit presets. Panel shapes, poses, jitter and animation timing are retained; tint opacity is controlled consistently across tones and the keyline is independent of the background. Reduce Transparency is an accessibility override. Independent custom images and a dot preset are new native features, not part of the supplied upstream implementation.
