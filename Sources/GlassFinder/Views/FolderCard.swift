import SwiftUI
import AppKit
import GlassFinderCore

@MainActor
struct FolderCard: View {
    @ObservedObject var folder: FolderItem
    @EnvironmentObject private var model: AppModel
    @State private var hovered = false
    private var selected: Bool { model.selection == folder.id }

    var body: some View {
        VStack(spacing: 2) {
            if model.preferences.isEnabled {
                GlassFolderView(images: folder.images, names: folder.files.map { $0.url.lastPathComponent },
                                selected: selected, hovered: hovered,
                                preferences: model.preferences)
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: folder.url.path))
                    .resizable().scaledToFit().frame(width: 140, height: 130)
                    .frame(width: 210, height: 326 * 210 / 340)
            }
            Text(folder.url.lastPathComponent)
                .font(.system(size: 13)).lineLimit(2).multilineTextAlignment(.center)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .foregroundStyle(selected ? Color.white : .primary)
                .background(selected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 4))
                .frame(maxWidth: 190)
            Text(folder.message ?? " ")
                .font(.caption2).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: 190)
        }
        .frame(width: 218, height: 250)
        .contentShape(Rectangle())
        .overlay {
            FolderClickSurface(single: { model.select(folder.id) }, double: { model.selection = folder.id; model.open(folder) }, key: { code in
                switch code {
                case 123, 126: model.moveSelection(-1)
                case 124, 125: model.moveSelection(1)
                case 53: model.dismissSelection()
                case 36, 49:
                    if let selected = model.folders.first(where: { $0.id == model.selection }) { model.open(selected) }
                default: return false
                }
                return true
            }, url: folder.url)
                .accessibilityHidden(true)
        }
        .onHover { hovered = $0 }
        .onChange(of: model.preferences.isEnabled) { _, enabled in if !enabled { hovered = false } }
        .onChange(of: model.interactionGeneration) { _, _ in hovered = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(folder.url.lastPathComponent)
        .accessibilityValue(selected ? "Selected folder" : "Folder")
        .accessibilityHint("Activate to open in Finder")
        .accessibilityAction { model.open(folder) }
        .contextMenu {
            Button("Open in Finder") { model.open(folder) }
            Button("Remove from GlassFinder") { model.remove(folder) }
        }
        .help(folder.message ?? folder.url.path)
    }
}

/// NSEvent.clickCount uses the user's double-click interval; the first click selects immediately.
@MainActor
private struct FolderClickSurface: NSViewRepresentable {
    var single: () -> Void
    var double: () -> Void
    var key: (UInt16) -> Bool
    var url: URL
    func makeNSView(context: Context) -> ClickView { ClickView() }
    func updateNSView(_ view: ClickView, context: Context) {
        view.single = single; view.double = double; view.key = key; view.url = url
    }

    final class ClickView: NSView, NSDraggingSource, FolderInteractionRegion {
        var single: (() -> Void)?
        var double: (() -> Void)?
        var key: ((UInt16) -> Bool)?
        var url: URL?
        private var down: NSPoint?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            if key?(event.keyCode) != true { super.keyDown(with: event) }
        }
        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            down = event.locationInWindow
            if event.clickCount == 1 { single?() }
            else if event.clickCount == 2 { double?() }
        }
        override func mouseDragged(with event: NSEvent) {
            guard let down, hypot(event.locationInWindow.x - down.x, event.locationInWindow.y - down.y) > 5,
                  let url else { return }
            self.down = nil
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let point = convert(event.locationInWindow, from: nil)
            item.setDraggingFrame(NSRect(x: point.x - 24, y: point.y - 24, width: 48, height: 48),
                                  contents: NSWorkspace.shared.icon(forFile: url.path))
            beginDraggingSession(with: [item], event: event, source: self)
        }
        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }
    }
}
