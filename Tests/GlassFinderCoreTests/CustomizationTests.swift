import XCTest
@testable import GlassFinderCore

final class CustomizationTests: XCTestCase {
    func testIndependentProfilesAndGradientPersistence() throws {
        var preferences = Preferences()
        let dark = preferences.darkProfile
        preferences.lightProfile.transparency = 0.43
        preferences.lightProfile.tint = RGBColor(0.8, 0.2, 0.4)
        preferences.lightProfile.keyline.addStop(at: 0.72)
        preferences.lightProfile.keyline.angle = 147
        preferences.lightProfile.showItemCount = true
        XCTAssertEqual(preferences.darkProfile, dark)
        let light = preferences.lightProfile
        preferences.darkProfile.keyline.stops[0].opacity = 0.3
        preferences.darkProfile.background = .ember
        XCTAssertEqual(preferences.lightProfile, light)
        let saved = try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(preferences))
        XCTAssertEqual(saved, preferences)
    }

    func testAutomaticOnlySelectsTheCorrectSavedProfile() {
        var preferences = Preferences()
        preferences.lightProfile.transparency = 0.3
        preferences.darkProfile.transparency = 0.85
        XCTAssertEqual(preferences.profile(for: preferences.activeTone(systemIsDark: false)).transparency, 0.3)
        XCTAssertEqual(preferences.profile(for: preferences.activeTone(systemIsDark: true)).transparency, 0.85)
        preferences.appearance = .light
        XCTAssertEqual(preferences.activeTone(systemIsDark: true), .light)
        preferences.appearance = .dark
        XCTAssertEqual(preferences.activeTone(systemIsDark: false), .dark)
    }

    func testV11MigrationPreservesBothBackgroundsAndSharedTransparency() throws {
        let source = Data(#"{"transparency":0.63,"lightBackground":"aurora","darkBackground":"custom","previewCount":4,"reduceMotion":true}"#.utf8)
        let saved = try JSONDecoder().decode(Preferences.self, from: source)
        XCTAssertEqual(saved.lightProfile.transparency, 0.63)
        XCTAssertEqual(saved.darkProfile.transparency, 0.63)
        XCTAssertEqual(saved.lightProfile.background, .aurora)
        XCTAssertEqual(saved.darkProfile.background, .custom)
        XCTAssertFalse(saved.lightProfile.showItemCount)
        XCTAssertTrue(saved.reduceMotion)
        XCTAssertEqual(saved.previewCount, 4)
    }

    func testGradientInterpolationAndStopEditing() throws {
        var gradient = KeylineGradient.defaults(for: .light)
        gradient.stops = [KeylineStop(position: 0, color: RGBColor(0, 0, 0), opacity: 0.2),
                          KeylineStop(position: 1, color: RGBColor(1, 1, 1), opacity: 0.8)]
        let id = try XCTUnwrap(gradient.addStop(at: 0.25))
        let stop = try XCTUnwrap(gradient.stops.first { $0.id == id })
        XCTAssertEqual(stop.color.red, 0.25, accuracy: 0.0001)
        XCTAssertEqual(stop.opacity, 0.35, accuracy: 0.0001)
        let index = try XCTUnwrap(gradient.stops.firstIndex { $0.id == id })
        gradient.stops[index].position = 1.4
        gradient.angle = -45
        gradient.normalize()
        XCTAssertEqual(gradient.stops.first { $0.id == id }?.position, 1)
        XCTAssertEqual(gradient.angle, 315)
        gradient.removeStop(id)
        XCTAssertEqual(gradient.stops.count, 2)
        gradient.removeStop(gradient.stops[0].id)
        XCTAssertEqual(gradient.stops.count, 2)
    }

    func testGradientBoundsAndHexValidation() {
        XCTAssertEqual(RGBColor(hex: "#80A0FF")?.hex, "#80A0FF")
        XCTAssertNil(RGBColor(hex: "#12345G"))
        XCTAssertNil(RGBColor(hex: "#1234567"))
        var gradient = KeylineGradient.defaults(for: .dark)
        for _ in 0..<20 { gradient.addStop(at: 0.5) }
        XCTAssertEqual(gradient.stops.count, 12)
        XCTAssertNil(gradient.addStop(at: 0.2))
        gradient.stops = []
        gradient.normalize()
        XCTAssertEqual(gradient.stops.count, 3)
        let dark = KeylineGradient.defaults(for: .dark)
        XCTAssertGreaterThan(dark.stops[0].color.red, dark.stops[2].color.red)
        XCTAssertLessThan(dark.stops[0].color.red, 0.6)
    }

    func testActualCountIsIndependentOfPreviewLimitAndNeverRecursive() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for index in 0..<100 { try Data().write(to: directory.appendingPathComponent("file-\(index).txt")) }
        let subfolder = directory.appendingPathComponent("subfolder")
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
        try Data().write(to: subfolder.appendingPathComponent("nested.txt"))
        try Data().write(to: directory.appendingPathComponent(".hidden"))
        let catalog = FileCatalog()
        let five = try await catalog.snapshot(of: directory, limit: 5)
        let ten = try await catalog.snapshot(of: directory, limit: 10)
        XCTAssertEqual(five.itemCount, 102)
        XCTAssertEqual(ten.itemCount, 102)
        XCTAssertEqual(five.files.count, 5)
        XCTAssertEqual(ten.files.count, 10)
        XCTAssertFalse(ten.files.contains { $0.url.lastPathComponent == ".hidden" })
    }

    func testEmptyAndUnavailableCountsRemainDistinct() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let empty = try await FileCatalog().snapshot(of: directory, limit: 10)
        XCTAssertEqual(empty.itemCount, 0)
        try FileManager.default.removeItem(at: directory)
        do {
            _ = try await FileCatalog().snapshot(of: directory, limit: 10)
            XCTFail("An unavailable directory must throw instead of claiming zero items")
        } catch { }
    }

    func testPreviewBoundsAndTenItemFanRemainBounded() {
        var preferences = Preferences()
        XCTAssertEqual(preferences.previewCount, 5)
        preferences.previewCount = 100
        preferences.normalize()
        XCTAssertEqual(preferences.previewCount, 10)
        preferences.previewCount = 0
        preferences.normalize()
        XCTAssertEqual(preferences.previewCount, 1)
        for count in 1...10 {
            for index in 0..<count {
                XCTAssertLessThanOrEqual(FolderPose.open.depthOffset(index: index, count: count), 90)
                XCTAssertGreaterThanOrEqual(FolderPose.open.depthOffset(index: index, count: count), 0)
            }
        }
        XCTAssertEqual(FolderSize.medium.iconWidth, 64)
        XCTAssertLessThan(FolderSize.small.cellHeight, FolderSize.medium.cellHeight)
        XCTAssertLessThan(FolderSize.medium.cellHeight, FolderSize.large.cellHeight)
    }
}
