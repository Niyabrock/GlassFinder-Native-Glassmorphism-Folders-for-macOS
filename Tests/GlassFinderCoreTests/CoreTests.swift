import XCTest
@testable import GlassFinderCore

final class CoreTests: XCTestCase {
    func testReferencePosesAndDeterministicFan() {
        XCTAssertEqual(FolderPose.resolve(selected: true, hovered: true, hoverEnabled: true), .open)
        XCTAssertEqual(FolderPose.resolve(selected: false, hovered: true, hoverEnabled: true), .hover)
        XCTAssertEqual(FolderPose.resolve(selected: false, hovered: true, hoverEnabled: false), .closed)
        XCTAssertEqual(FolderPose.hover.hinge, -11)
        XCTAssertEqual(FolderPose.open.hinge, -24)
        XCTAssertEqual(FolderPose.open.lift, -96)
        XCTAssertEqual((0..<5).map { FolderPose.fanSlot(index: $0, count: 5) }, [-1, -0.5, 0, 0.5, 1])
        XCTAssertEqual(FolderPose.fanSlot(index: 0, count: 1), 0)
        // Compared with the supplied TypeScript rng/hashString implementation, not a Swift self-comparison.
        let jitter = FolderPose.jitter(name: "Brief.pdf", index: 2)
        XCTAssertEqual(jitter.x, 2.27423143805936, accuracy: 0.000000001)
        XCTAssertEqual(jitter.rotation, -1.4716708071529867, accuracy: 0.000000001)
    }

    func testSelectionPersistsAndDisableWins() {
        XCTAssertEqual(FolderPresentation.openness(enabled: true, selected: true, hovered: false, hoverEnabled: true), 1)
        XCTAssertEqual(FolderPresentation.openness(enabled: true, selected: false, hovered: true, hoverEnabled: true), 0.65)
        XCTAssertEqual(FolderPresentation.openness(enabled: true, selected: false, hovered: true, hoverEnabled: false), 0)
        XCTAssertEqual(FolderPresentation.openness(enabled: false, selected: true, hovered: true, hoverEnabled: true), 0)
    }

    func testPreferencesRoundTripAndBounds() throws {
        var preferences = Preferences()
        preferences.previewCount = 100
        preferences.animationSpeed = -1
        preferences.transparency = .infinity
        preferences.normalize()
        XCTAssertEqual(preferences.previewCount, 5)
        XCTAssertEqual(preferences.animationSpeed, 0.5)
        XCTAssertEqual(preferences.transparency, 0.55)
        XCTAssertEqual(try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(preferences)), preferences)
    }

    func testCatalogUsesActualContentsAndDoesNotMutateFiles() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for name in ["b.txt", "a.txt", ".hidden"] {
            try Data(name.utf8).write(to: directory.appendingPathComponent(name))
        }
        let catalog = FileCatalog()
        let files = try await catalog.contents(of: directory, limit: 5)
        XCTAssertEqual(files.map { $0.url.lastPathComponent }, ["a.txt", "b.txt"])
        let limited = try await catalog.contents(of: directory, limit: 1)
        XCTAssertEqual(limited.count, 1)
        let zero = try await catalog.contents(of: directory, limit: 0)
        XCTAssertTrue(zero.isEmpty)
        XCTAssertEqual(try String(contentsOf: directory.appendingPathComponent("a.txt")), "a.txt")
    }

    func testMissingDirectoryReportsError() async {
        do {
            _ = try await FileCatalog().contents(of: URL(fileURLWithPath: "/missing-\(UUID())"), limit: 5)
            XCTFail("Expected unavailable folder error")
        } catch { XCTAssertFalse(error is CancellationError) }
    }
}
