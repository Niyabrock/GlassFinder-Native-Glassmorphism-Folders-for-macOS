import AppKit
import SwiftUI
import GlassFinderCore

/// Non-mutating integration alternative. It never calls setIcon or writes Finder tags/xattrs.
@MainActor
enum StaticIconExporter {
    static func png(preferences: Preferences, backgrounds: BackgroundStore, tone: BackgroundTone) throws -> Data {
        var snapshot = preferences
        snapshot.editAppearance(tone)
        snapshot.animationIntensity = 0
        snapshot.hoverPreviews = false
        snapshot.lightProfile.showItemCount = false
        snapshot.darkProfile.showItemCount = false
        let content = ZStack {
            GlassFolderView(images: [], names: [], selected: false, hovered: false, preferences: snapshot, displayWidth: 940)
        }
        .frame(width: 1024, height: 1024)
        .environmentObject(backgrounds)
        .environment(\.colorScheme, tone == .dark ? .dark : .light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        renderer.isOpaque = false
        guard let image = renderer.cgImage,
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }
}
