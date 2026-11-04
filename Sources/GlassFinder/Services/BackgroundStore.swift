import AppKit
import ImageIO
import GlassFinderCore

/// Imported images become bounded, app-owned PNGs; no source file is modified or needed on relaunch.
@MainActor
final class BackgroundStore: ObservableObject {
    @Published private var images: [BackgroundTone: NSImage] = [:]
    private let directory: URL

    init() {
        // Deliberately retain the former name on disk so existing imports survive the display rename.
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GlassFinder/Backgrounds", isDirectory: true)
        for tone in BackgroundTone.allCases { images[tone] = NSImage(contentsOf: location(tone)) }
    }

    func image(for tone: BackgroundTone) -> NSImage? { images[tone] }

    func importImage(_ url: URL, for tone: BackgroundTone) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary),
              let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try png.write(to: location(tone), options: .atomic)
        images[tone] = NSImage(cgImage: cgImage, size: .zero)
    }

    func remove(_ tone: BackgroundTone) throws {
        let url = location(tone)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        images[tone] = nil
    }

    private func location(_ tone: BackgroundTone) -> URL { directory.appendingPathComponent(tone.rawValue + ".png") }
}
