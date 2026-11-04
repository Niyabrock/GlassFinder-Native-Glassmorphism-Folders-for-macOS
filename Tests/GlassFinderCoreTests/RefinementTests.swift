import XCTest
@testable import GlassFinderCore

final class RefinementTests: XCTestCase {
    func testApprovedPalette() {
        XCTAssertEqual(FolderTint.allCases.map(\.hex), ["#F07D71", "#F5BD67", "#FBE772", "#8FE586", "#67A3F9", "#CC88F9", "#B5B5B8"])
        for tint in FolderTint.allCases { XCTAssertEqual(tint.color.hex, tint.hex) }
    }

    func testSynchronizedAppearanceSelectionPreservesIndependentValues() {
        var preferences = Preferences()
        preferences.lightProfile.transparency = 0.4
        preferences.darkProfile.transparency = 0.8
        preferences.appearance = .automatic
        XCTAssertEqual(preferences.activeTone(systemIsDark: true), .dark)
        preferences.editAppearance(.light)
        XCTAssertEqual(preferences.appearance, .light)
        XCTAssertEqual(preferences.activeTone(systemIsDark: true), .light)
        preferences.editAppearance(.dark)
        XCTAssertEqual(preferences.appearance, .dark)
        XCTAssertEqual(preferences.lightProfile.transparency, 0.4)
        XCTAssertEqual(preferences.darkProfile.transparency, 0.8)
    }

    func testDarkDefaultsDoNotOverrideSavedAutomaticChoice() throws {
        XCTAssertEqual(Preferences().appearance, .dark)
        let saved = try JSONDecoder().decode(Preferences.self, from: Data(#"{"appearance":"automatic"}"#.utf8))
        XCTAssertEqual(saved.appearance, .automatic)
        XCTAssertEqual(saved.activeTone(systemIsDark: false), .light)
    }

    func testExistingProfileDataMigratesWithoutLosingItsGradientOrTint() throws {
        var old = Preferences()
        old.lightProfile.tint = GlassFinderCore.RGBColor(0.2, 0.4, 0.6)
        old.darkProfile.background = .custom
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        for name in ["lightProfile", "darkProfile"] {
            var profile = try XCTUnwrap(json[name] as? [String: Any])
            profile.removeValue(forKey: "imagePlacement"); profile.removeValue(forKey: "presetTint")
            json[name] = profile
        }
        let restored = try JSONDecoder().decode(Preferences.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(restored.lightProfile.tint, old.lightProfile.tint)
        XCTAssertEqual(restored.darkProfile.keyline, old.darkProfile.keyline)
        XCTAssertEqual(restored.darkProfile.background, .custom)
        XCTAssertEqual(restored.lightProfile.imagePlacement, ImagePlacement())
    }

    func testFolderOverrideDoesNotMutateGlobalProfiles() {
        var preferences = Preferences()
        preferences.lightProfile.presetTint = .blue
        var override = FolderCustomization()
        override.tint = .red
        let rendered = override.applying(to: preferences)
        XCTAssertEqual(rendered.lightProfile.effectiveTint, FolderTint.red.color)
        XCTAssertEqual(rendered.darkProfile.effectiveTint, FolderTint.red.color)
        XCTAssertEqual(preferences.lightProfile.presetTint, .blue)
        override.tint = nil
        XCTAssertEqual(override.applying(to: preferences).lightProfile.effectiveTint, FolderTint.blue.color)
    }

    func testImageDimensionsRespectAspectLockAndNormalizedPosition() {
        var placement = ImagePlacement()
        placement.resizeWidth(1.5)
        placement.scale = 1.2; placement.x = 0.25
        let frame = placement.frame(aspectRatio: 2)
        XCTAssertEqual(frame.width / frame.height, 2, accuracy: 0.0001)
        XCTAssertEqual(frame.centerX, 255)
        placement.setAspectLocked(false); placement.resizeHeight(0.75)
        let stretched = placement.frame(aspectRatio: 2)
        XCTAssertEqual(stretched.width / stretched.height, 4, accuracy: 0.0001)
        placement.setAspectLocked(true)
        XCTAssertEqual(placement.frame(aspectRatio: 2).width / placement.frame(aspectRatio: 2).height, 2, accuracy: 0.0001)
        // Folder display scaling is applied after this canonical frame, so aspect/placement are invariant.
        for scale in [48.0 / 340, 64.0 / 340, 96.0 / 340] {
            XCTAssertEqual(frame.width * scale / (frame.height * scale), 2, accuracy: 0.0001)
        }
    }

    func testStableFolderIdentityAndIndependentTransformsRoundTrip() throws {
        var customization = FolderCustomization()
        customization.tint = .purple
        var light = ImagePlacement(); light.x = 0.3
        var dark = ImagePlacement(); dark.scale = 2
        customization.setPlacement(light, for: .light)
        customization.setPlacement(dark, for: .dark)
        let record = SavedFolder(id: UUID(), bookmark: Data([1, 2, 3]), customization: customization)
        let restored = try JSONDecoder().decode(SavedFolder.self, from: JSONEncoder().encode(record))
        XCTAssertEqual(restored, record)
        XCTAssertEqual(restored.customization.placement(for: .light)?.x, 0.3)
        XCTAssertEqual(restored.customization.placement(for: .dark)?.scale, 2)
        XCTAssertEqual(restored.id, record.id) // Identity is persisted; it is not derived from a display name.
    }

    func testPlacementValidationHandlesInvalidValues() {
        var placement = ImagePlacement()
        placement.x = .infinity; placement.y = -9; placement.width = 0; placement.scale = .nan
        placement.normalize()
        XCTAssertEqual(placement.x, 0)
        XCTAssertEqual(placement.y, -1.5)
        XCTAssertEqual(placement.width, 0.25)
        XCTAssertEqual(placement.height, placement.width)
        XCTAssertEqual(placement.scale, 1)
    }
}
